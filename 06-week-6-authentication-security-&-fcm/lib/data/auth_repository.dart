import 'api_client.dart';
import 'token_store.dart';

class UserModel {
  final String id;
  final String email;
  final String name;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
      };
}

class AuthRepository {
  final ApiClient apiClient;
  final TokenStore tokenStore;

  AuthRepository({
    required this.apiClient,
    required this.tokenStore,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Simulated authentication logic for development/demonstration
    await Future.delayed(const Duration(milliseconds: 500));
    final dummyToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    final dummyRefreshToken = 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
    await tokenStore.saveTokens(
      accessToken: dummyToken,
      refreshToken: dummyRefreshToken,
    );
    final username = email.split('@').first;
    return UserModel(
      id: 'user_1',
      email: email,
      name: username.isNotEmpty ? username : 'User',
    );
  }

  Future<void> logout() async {
    await tokenStore.clearTokens();
  }

  Future<bool> isAuthenticated() async {
    return await tokenStore.hasToken();
  }
}
