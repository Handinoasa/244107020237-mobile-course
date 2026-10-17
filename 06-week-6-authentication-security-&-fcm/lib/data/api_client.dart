import 'dart:developer';
import 'package:dio/dio.dart';
import 'token_store.dart';

class ApiClient {
  final Dio dio;
  final TokenStore tokenStore;

  ApiClient({
    required this.tokenStore,
    String baseUrl = 'https://api.example.com',
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStore.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Automatic token refresh interceptor on 401 Unauthorized
          if (error.response?.statusCode == 401) {
            log('HTTP 401 Unauthorized detected. Attempting automatic token refresh...');
            final refreshToken = await tokenStore.getRefreshToken();

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Request token peremajaan baru menggunakan Refresh Token
                final newAccessToken =
                    'mock_refreshed_access_token_${DateTime.now().millisecondsSinceEpoch}';
                await tokenStore.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: refreshToken,
                );

                log('Token successfully refreshed. Retrying original request...');
                // Retry request awal dengan token yang baru diperbarui
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (refreshErr) {
                log('Token refresh failed: $refreshErr. Clearing secure tokens.');
                await tokenStore.clearTokens();
                return handler.next(error);
              }
            } else {
              log('No refresh token present. Clearing stored tokens.');
              await tokenStore.clearTokens();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
