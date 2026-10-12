import 'dart:async';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/post.dart';

class PostRepository {
  PostRepository({Dio? dio, Future<Database> Function()? openDb})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
              ),
            ),
        _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((r) => Post.fromPayload(r['payload'] as String)).toList();
  }

  Future<void> savePostsToCache(List<Post> posts) async {
    final db = await _openDb();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final post in posts) {
      batch.insert(
        'cached_posts',
        {
          'id': post.id,
          'payload': post.toPayload(),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Post>> fetchFromNetwork({bool forceOffline = false}) async {
    if (forceOffline) {
      throw Exception('Simulasi Offline: Jaringan tidak tersedia.');
    }
    final response =
        await _dio.get('https://jsonplaceholder.typicode.com/posts');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Post>> loadPostsCacheFirst({
    bool forceOffline = false,
    void Function(List<Post> freshPosts)? onBackgroundUpdated,
  }) async {
    final cached = await readCachedPosts();

    // 1. Segera kembalikan cache agar UI tidak blank saat offline
    // 2. Di background: fetch -> simpan ke cached_posts -> notify callback
    unawaited(_refreshInBackground(
      forceOffline: forceOffline,
      onBackgroundUpdated: onBackgroundUpdated,
    ));

    return cached;
  }

  Future<void> _refreshInBackground({
    bool forceOffline = false,
    void Function(List<Post> freshPosts)? onBackgroundUpdated,
  }) async {
    try {
      final fresh = await fetchFromNetwork(forceOffline: forceOffline);
      await savePostsToCache(fresh);
      onBackgroundUpdated?.call(fresh);
    } catch (_) {
      // Abaikan error jaringan di background agar cache tetap tampil
    }
  }

  Future<String?> getLastCachedTime() async {
    final db = await _openDb();
    final rows =
        await db.query('cached_posts', columns: ['cached_at'], limit: 1);
    if (rows.isNotEmpty) {
      return rows.first['cached_at'] as String?;
    }
    return null;
  }
}
