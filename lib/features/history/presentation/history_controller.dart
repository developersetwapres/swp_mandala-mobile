// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../domain/history_entry.dart';
import '../domain/history_failure.dart';
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
  HistoryController({
    required HistoryRepository repository,
    this.pageSize = 12,
    this.loadMoreDelay = const Duration(milliseconds: 220),
  }) : _repository = repository;

  final HistoryRepository _repository;
  final int pageSize;
  final Duration loadMoreDelay;

  List<HistoryEntry> _allEntries = const [];
  HistoryFilter _filter = HistoryFilter.all;
  String _query = '';
  int _visibleCount = 0;
  bool _initialLoading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  HistoryFailure? _failure;
  HistoryFailure? _refreshFailure;

  List<HistoryEntry> get allEntries => _allEntries;
  HistoryFilter get filter => _filter;
  String get query => _query;
  bool get initialLoading => _initialLoading;
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  HistoryFailure? get failure => _failure;
  HistoryFailure? get refreshFailure => _refreshFailure;

  List<HistoryEntry> get matchingEntries {
    final normalizedQuery = _query.trim().toLowerCase();
    return _allEntries
        .where((entry) {
          final serviceType = _filter.serviceType;
          if (serviceType != null && entry.serviceType != serviceType) {
            return false;
          }
          return normalizedQuery.isEmpty ||
              entry.searchText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<HistoryEntry> get visibleEntries =>
      matchingEntries.take(_visibleCount).toList(growable: false);

  bool get hasMore => _visibleCount < matchingEntries.length;

  Future<void> load() async {
    if (_initialLoading) return;
    _initialLoading = true;
    _failure = null;
    notifyListeners();
    try {
      _allEntries = await _repository.getHistory();
      _visibleCount = pageSize;
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
      _allEntries = await _repository.getHistory();
      _visibleCount = pageSize;
      _failure = null;
    } on HistoryFailure catch (failure) {
      _refreshFailure = failure;
      if (_allEntries.isEmpty) _failure = failure;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void setFilter(HistoryFilter value) {
    if (_filter == value) return;
    _filter = value;
    _visibleCount = pageSize;
    notifyListeners();
  }

  void setQuery(String value) {
    final normalized = value.trim();
    if (_query == normalized) return;
    _query = normalized;
    _visibleCount = pageSize;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || _initialLoading) return;
    _loadingMore = true;
    notifyListeners();
    if (loadMoreDelay > Duration.zero) {
      await Future<void>.delayed(loadMoreDelay);
    }
    _visibleCount = (_visibleCount + pageSize).clamp(0, matchingEntries.length);
    _loadingMore = false;
    notifyListeners();
  }

  void clearRefreshFailure() => _refreshFailure = null;
}
