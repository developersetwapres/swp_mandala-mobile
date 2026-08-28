import 'history_entry.dart';
import 'history_page_result.dart';

abstract interface class HistoryRepository {
  Future<HistoryPageResult> getHistoryPage({int page = 1, String search = ''});

  Future<List<HistoryEntry>> getHistory() async =>
      (await getHistoryPage()).entries;
}
