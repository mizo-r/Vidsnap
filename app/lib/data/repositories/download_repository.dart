import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:vidsnap/data/models/download_task.dart';
import 'package:vidsnap/data/repositories/storage_service.dart';

/// Repository for download tasks (active, paused, completed, failed).
class DownloadRepository {
  DownloadRepository(this._box);

  final Box<DownloadTask> _box;

  List<DownloadTask> get all =>
      _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<DownloadTask> get active =>
      all.where((t) => t.isActive).toList();

  List<DownloadTask> get completed =>
      all.where((t) => t.isCompleted).toList();

  List<DownloadTask> get failed =>
      all.where((t) => t.isFailed).toList();

  DownloadTask? getById(String id) =>
      _box.values.cast<DownloadTask?>().firstWhere((t) => t?.id == id, orElse: () => null);

  Future<void> add(DownloadTask task) => _box.put(task.id, task);

  Future<void> update(DownloadTask task) => _box.put(task.id, task);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> deleteCompleted() async {
    final ids = completed.map((t) => t.id).toList();
    await _box.deleteAll(ids);
  }

  Future<void> clearAll() => _box.clear();

  Stream<BoxEvent> watch() => _box.watch();
}

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final box = ref.watch(downloadsBoxProvider);
  return DownloadRepository(box);
});
