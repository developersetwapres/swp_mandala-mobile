import 'history_entry.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryEntry>> getHistory();
}
