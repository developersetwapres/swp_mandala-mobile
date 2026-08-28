import 'package:flutter/foundation.dart';

import '../domain/history_entry.dart';
import '../domain/history_failure.dart';
import '../domain/history_page_result.dart';
import '../domain/history_repository.dart';

enum HistoryFilter { all, meetingRoom, officeSupply, damage }

extension HistoryFilterPresentation on HistoryFilter {
  String get label => switch (this) {
    HistoryFilter.all => 'Semua',
    HistoryFilter.meetingRoom => 'Ruangan Rapat',
    HistoryFilter.officeSupply => 'ATK',
    HistoryFilter.damage => 'Kerusakan',
  };

  HistoryServiceType? get serviceType => switch (this) {
    HistoryFilter.all => null,
    HistoryFilter.meetingRoom => HistoryServiceType.meetingRoom,
    HistoryFilter.officeSupply => HistoryServiceType.officeSupply,
    HistoryFilter.damage => HistoryServiceType.damage,
  };
}

class HistoryController extends ChangeNotifier {
  HistoryController({required HistoryRepository repository})
    : _repository = repository;

  final HistoryRepository _repository;
  HistoryPageResult? _page;
  HistoryFilter _filter = HistoryFilter.all;
  String _query = '';
  bool _initialLoading = false;
  bool _refreshing = false;
  bool _loadingPage = false;
  HistoryFailure? _failure;
  HistoryFailure? _refreshFailure;

  List<HistoryEntry> get allEntries => _page?.entries ?? const [];
  HistoryFilter get filter => _filter;
  String get query => _query;
  bool get initialLoading => _initialLoading;
  bool get refreshing => _refreshing;
  bool get loadingPage => _loadingPage;
  HistoryFailure? get failure => _failure;
  HistoryFailure? get refreshFailure => _refreshFailure;

  List<HistoryEntry> get matchingEntries => allEntries.where((entry) {
    final serviceType = _filter.serviceType;
    return serviceType == null || entry.serviceType == serviceType;
  }).toList(growable: false);

  List<HistoryEntry> get visibleEntries => matchingEntries;
  int get currentPage => _page?.currentPage ?? 1;
  int get lastPage => _page?.lastPage ?? 1;
  int get total => _page?.total ?? 0;
  int? get from => _page?.from;
  int? get to => _page?.to;
  List<HistoryPageLink> get pageLinks => _page?.pageLinks ?? const [];
  bool get hasPreviousPage => _page?.previousPage != null;
  bool get hasNextPage => _page?.nextPage != null;

  Future<void> load() async {
    if (_initialLoading) return;
    _initialLoading = true;
    _failure = null;
    notifyListeners();
    try {
      _page = await _repository.getHistoryPage(search: _query);
    } on HistoryFailure catch (failure) {
      _failure = failure;
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _refreshFailure = null;
    notifyListeners();
    try {
      _page = await _repository.getHistoryPage(
        page: currentPage,
        search: _query,
      );
      _failure = null;
    } on HistoryFailure catch (failure) {
      _refreshFailure = failure;
      if (_page == null) _failure = failure;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void setFilter(HistoryFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  Future<void> setQuery(String value) async {
    final normalized = value.trim();
    if (_query == normalized) return;
    _query = normalized;
    await _loadPage(1);
  }

  Future<void> previousPage() => _loadPage(currentPage - 1);
  Future<void> nextPage() => _loadPage(currentPage + 1);
  Future<void> goToPage(int page) => _loadPage(page);

  Future<void> _loadPage(int page) async {
    if (_loadingPage || page < 1 || page > lastPage) return;
    _loadingPage = true;
    _refreshFailure = null;
    notifyListeners();
    try {
      _page = await _repository.getHistoryPage(page: page, search: _query);
      _failure = null;
    } on HistoryFailure catch (failure) {
      _refreshFailure = failure;
      if (_page == null) _failure = failure;
    } finally {
      _loadingPage = false;
      notifyListeners();
    }
  }

  void clearRefreshFailure() => _refreshFailure = null;
}
