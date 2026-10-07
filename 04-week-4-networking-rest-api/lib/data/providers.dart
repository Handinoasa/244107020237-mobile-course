import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(dioProvider));
});

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // ----------------------------------------------------
    // TAMBAHKAN BARIS INI UNTUK MENAHAN LOADING SELAMA 3 DETIK
    await Future.delayed(const Duration(seconds: 3));
    // ----------------------------------------------------
    return ref.watch(postRepositoryProvider).fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(postRepositoryProvider).fetchPosts(),
    );
  }
}

final postListProvider =
    AsyncNotifierProvider.autoDispose<PostListNotifier, List<Post>>(
      PostListNotifier.new,
    );

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi terputus. Silakan periksa jaringan Anda.';
    }
    return 'Terjadi kesalahan jaringan atau server.';
  }
  return 'Terjadi kesalahan sistem: $error';
}
