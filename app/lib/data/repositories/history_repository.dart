import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/data/models/history_item.dart';
import 'package:vidsnap/data/repositories/storage_service.dart';

class HistoryRepository {
  HistoryRepository(this._box);

  final Box<HistoryItem> _box;

  List<HistoryItem> get all =>
      _box.values.toList()..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

  Future<void> add(HistoryItem item) => _box.put(item.id, item);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clearAll() => _box.clear();

  Stream<BoxEvent> watch() => _box.watch();
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final box = ref.watch(historyBoxProvider);
  return HistoryRepository(box);
});
