import 'history_entry.dart';

/// A single server-provided page from the history endpoint.
class HistoryPageResult {
  const HistoryPageResult({
    required this.entries,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.from,
    required this.to,
    required this.pageLinks,
    this.previousPage,
    this.nextPage,
  });

  final List<HistoryEntry> entries;
  final int currentPage;
  final int lastPage;
  final int total;
  final int? from;
  final int? to;
  final List<HistoryPageLink> pageLinks;
  final int? previousPage;
  final int? nextPage;
}

class HistoryPageLink {
  const HistoryPageLink({required this.page, required this.active});

  final int page;
  final bool active;
}
