import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/local/post.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/post_repository.dart';
import 'settings_page.dart';

// ==========================================
// PROVIDERS & NOTIFIERS
// ==========================================

// --- Praktikum 3.3: Toggle Simulasi Offline Deterministik ---
final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setOffline(bool value) => state = value;
}

// --- Praktikum 2 & 3.2: Note Repository & Notes List ---
final noteRepositoryProvider = Provider((ref) => NoteRepository());

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    return ref.watch(noteRepositoryProvider).fetchNotes();
  }

  Future<void> add(String title, String body) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(noteRepositoryProvider).addNote(title: title, body: body);
      return ref.read(noteRepositoryProvider).fetchNotes();
    });
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(noteRepositoryProvider).deleteNote(id);
      return ref.read(noteRepositoryProvider).fetchNotes();
    });
  }

  Future<int> sync() async {
    final repo = ref.read(noteRepositoryProvider);
    final forceOffline = ref.read(forceOfflineProvider);

    final syncedCount = await syncNotes(repo, forceOffline: forceOffline);
    ref.invalidateSelf();
    return syncedCount;
  }
}

final dirtyCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notesProvider);
  return ref.watch(noteRepositoryProvider).countDirty();
});

// --- Praktikum 3.1: Cache-First Post Repository & Notifier ---
final postRepositoryProvider = Provider((ref) => PostRepository());

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<Post>>(
  PostsNotifier.new,
);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repo = ref.watch(postRepositoryProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return repo.loadPostsCacheFirst(
      forceOffline: forceOffline,
      onBackgroundUpdated: (freshPosts) {
        state = AsyncData(freshPosts);
      },
    );
  }

  Future<void> refresh() async {
    final repo = ref.read(postRepositoryProvider);
    final forceOffline = ref.read(forceOfflineProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await repo.fetchFromNetwork(forceOffline: forceOffline);
      await repo.savePostsToCache(fresh);
      return fresh;
    });
  }
}

final lastCachedTimeProvider = FutureProvider<String?>((ref) async {
  ref.watch(postsProvider);
  return ref.watch(postRepositoryProvider).getLastCachedTime();
});

// ==========================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// ==========================================

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  int _currentIndex = 0;
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final syncedCount = await ref.read(notesProvider.notifier).sync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            syncedCount > 0
                ? 'Berhasil menyinkronkan $syncedCount catatan ke server!'
                : 'Semua catatan sudah tersinkron (tidak ada data dirty).',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Catatan Offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: Belanja Bulanan',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                hintText: 'Detail catatan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isNotEmpty) {
                ref.read(notesProvider.notifier).add(title, body);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final dirtyCount = dirtyAsync.value ?? 0;
    final isDark = ref.watch(darkModeProvider).value ?? false;
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Praktikum 2: Catatan Offline'
              : 'Praktikum 3: Cache & Sync',
        ),
        actions: [
          // Toggle Dark Mode (Praktikum 1)
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(darkModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildPraktikum2NotesView(dirtyCount)
          : _buildPraktikum3SyncView(dirtyCount, forceOffline),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: dirtyCount > 0,
              label: Text('$dirtyCount'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.note_alt_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: dirtyCount > 0,
              label: Text('$dirtyCount'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.note_alt),
            ),
            label: '(Notes)',
          ),
          NavigationDestination(
            icon: Icon(
              forceOffline
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_sync_outlined,
              color: forceOffline ? Colors.red : null,
            ),
            selectedIcon: Icon(
              forceOffline ? Icons.cloud_off : Icons.cloud_sync,
              color: forceOffline ? Colors.red : null,
            ),
            label: '(Sync)',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Catatan Baru'),
              tooltip: 'Tambah Catatan Offline',
            )
          : null,
    );
  }

  // ==========================================
  // VIEW PRAKTIKUM 2: CATATAN OFFLINE SQLITE
  // ==========================================
  Widget _buildPraktikum2NotesView(int dirtyCount) {
    final notesAsync = ref.watch(notesProvider);

    return Column(
      children: [
        // Header info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.storage,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Database SQLite Lokal (offline_notes.db)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Badge(
                label: Text('$dirtyCount'),
                backgroundColor: dirtyCount > 0 ? Colors.orange : Colors.green,
                child: const Icon(Icons.sync, size: 18),
              ),
            ],
          ),
        ),
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Terjadi kesalahan: $err')),
            data: (notes) {
              if (notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada catatan offline.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tekan tombol Catatan Baru di bawah untuk menambah data.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: notes.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Hapus catatan',
                                onPressed: () {
                                  if (note.id != null) {
                                    ref
                                        .read(notesProvider.notifier)
                                        .delete(note.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                          if (note.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              note.body,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withAlpha(200),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: note.dirty
                                      ? Colors.orange.withAlpha(50)
                                      : Colors.green.withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      note.dirty
                                          ? Icons.cloud_off
                                          : Icons.cloud_done,
                                      size: 14,
                                      color: note.dirty
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      note.dirty ? 'Belum Sync' : 'Tersinkron',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: note.dirty
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                note.updatedAt.toString().substring(0, 16),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW PRAKTIKUM 3: CACHE-FIRST & SYNC QUEUE
  // ==========================================
  Widget _buildPraktikum3SyncView(int dirtyCount, bool forceOffline) {
    final postsAsync = ref.watch(postsProvider);
    final lastCachedAsync = ref.watch(lastCachedTimeProvider);
    final lastCached = lastCachedAsync.value;

    return RefreshIndicator(
      onRefresh: () => ref.read(postsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 1. KONTROL SIMULASI OFFLINE DETERMINISTIK (Langkah 3.3)
          Card(
            color: forceOffline
                ? Colors.red.shade50
                : Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: forceOffline ? Colors.red : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: SwitchListTile(
              title: Text(
                'Simulasi Mode Offline: ${forceOffline ? "AKTIF" : "NONAKTIF"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: forceOffline ? Colors.red.shade900 : null,
                ),
              ),
              subtitle: Text(
                forceOffline
                    ? 'Jaringan terputus secara simulasi. Demo tetap deterministik.'
                    : 'Koneksi jaringan normal (Online).',
                style: const TextStyle(fontSize: 12),
              ),
              secondary: Icon(
                forceOffline ? Icons.wifi_off : Icons.wifi,
                color: forceOffline ? Colors.red : Colors.green,
                size: 32,
              ),
              value: forceOffline,
              onChanged: (val) =>
                  ref.read(forceOfflineProvider.notifier).setOffline(val),
            ),
          ),
          const SizedBox(height: 8),

          // 2. SINKRONISASI CATATAN KOTOR / DIRTY (Langkah 3.2)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_problem, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Antrean Catatan Kotor (Dirty Queue)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Badge(
                        label: Text('$dirtyCount item'),
                        backgroundColor: dirtyCount > 0
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dirtyCount > 0
                        ? 'Ada $dirtyCount catatan yang dibuat/diubah secara offline dan belum diunggah ke server.'
                        : 'Semua catatan lokal telah sinkron sempurna dengan server (dirty = 0).',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        _isSyncing
                            ? 'Mengunggah ke Server...'
                            : 'Sinkronkan Catatan (syncNotes)',
                      ),
                      onPressed: _isSyncing ? null : _handleSync,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. HEADER CACHE-FIRST API (Langkah 3.1)
          Row(
            children: [
              const Icon(Icons.cloud_download, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Data API Cache-First (GET /posts)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh dari Network',
                onPressed: () => ref.read(postsProvider.notifier).refresh(),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lastCached != null
                        ? 'Cache lokal SQLite tersimpan: ${lastCached.substring(0, 19)}'
                        : 'Memuat data dari API JSONPlaceholder...',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // DAFTAR POSTS DARI CACHE-FIRST
          postsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, size: 36, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal fetch background: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.read(postsProvider.notifier).refresh(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Belum ada data cache posts.')),
                  ),
                );
              }

              // Tampilkan 15 post teratas agar responsif
              final displayPosts = posts.take(15).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayPosts.length,
                separatorBuilder: (_, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final post = displayPosts[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          '${post.id}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
