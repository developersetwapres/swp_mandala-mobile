import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_scope.dart';
import '../../auth/presentation/profile_page.dart';
import '../../home/primary_navigation_bar.dart';
import '../domain/history_entry.dart';
import '../domain/history_failure.dart';
import '../domain/history_repository.dart';
import 'history_controller.dart';
import 'history_detail_page.dart';
import 'history_presentation.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({required this.repository, super.key});

  final HistoryRepository repository;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryController _controller;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _handlingUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(repository: widget.repository);
    _controller.addListener(_handleControllerEvent);
    _controller.load();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    _controller
      ..removeListener(_handleControllerEvent)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 260) {
      _controller.loadMore();
    }
  }

  void _handleControllerEvent() {
    final failure = _controller.failure ?? _controller.refreshFailure;
    if (failure?.type == HistoryFailureType.unauthorized &&
        !_handlingUnauthorized) {
      _controller.clearRefreshFailure();
      _handlingUnauthorized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _endSession());
      return;
    }
    final refreshFailure = _controller.refreshFailure;
    if (refreshFailure != null) {
      _controller.clearRefreshFailure();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(refreshFailure.message),
              margin: const EdgeInsets.all(20),
            ),
          );
      });
    }
  }

  Future<void> _endSession() async {
    if (!mounted) return;
    await AuthScope.of(context).logout();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 260),
      () => _controller.setQuery(value),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _controller.setQuery('');
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => RefreshIndicator(
            color: AppColors.primaryStrong,
            backgroundColor: AppColors.surface,
            onRefresh: _controller.refresh,
            child: CustomScrollView(
              key: const Key('history_scroll'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HistoryHero(total: _controller.allEntries.length),
                ),
                SliverToBoxAdapter(
                  child: _HistoryControls(
                    searchController: _searchController,
                    selectedFilter: _controller.filter,
                    onSearchChanged: _search,
                    onClearSearch: _clearSearch,
                    onFilterSelected: _controller.setFilter,
                  ),
                ),
                ..._contentSlivers(),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: PrimaryNavigationBar(
          selectedIndex: 1,
          onSelected: (index) {
            if (index == 0 && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (index == 2) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      ProfilePage(user: AuthScope.of(context).currentUser!),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  List<Widget> _contentSlivers() {
    if (_controller.initialLoading) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: _HistorySkeleton()),
        ),
      ];
    }
    final failure = _controller.failure;
    if (failure != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _HistoryError(
            message: failure.message,
            onRetry: _controller.load,
          ),
        ),
      ];
    }
    if (_controller.matchingEntries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _HistoryEmpty(
            allHistoryEmpty: _controller.allEntries.isEmpty,
            hasQuery: _controller.query.isNotEmpty,
            filter: _controller.filter,
            onReset: () {
              _clearSearch();
              _controller.setFilter(HistoryFilter.all);
            },
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        sliver: SliverList.separated(
          itemCount: _controller.visibleEntries.length,
          itemBuilder: (context, index) => _HistoryCard(
            key: Key('history_item_$index'),
            entry: _controller.visibleEntries[index],
            detailActionKey: Key('history_detail_action_$index'),
            onDetail: () => _openDetail(_controller.visibleEntries[index]),
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
        ),
      ),
      SliverToBoxAdapter(
        child: _PaginationFooter(
          loading: _controller.loadingMore,
          hasMore: _controller.hasMore,
          visible: _controller.visibleEntries.length,
          total: _controller.matchingEntries.length,
        ),
      ),
    ];
  }

  Future<void> _openDetail(HistoryEntry entry) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => HistoryDetailPage(entry: entry),
      ),
    );
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FAFF), Color(0xFFCDEEFE)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        total == 0 ? 'Aktivitas layanan' : '$total pengajuan',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primaryDeep),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pantau perjalanan seluruh pengajuan layananmu.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDeep.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x144187A8),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.manage_history_rounded,
                  color: AppColors.primaryStrong,
                  size: 31,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryControls extends StatelessWidget {
  const _HistoryControls({
    required this.searchController,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
  });

  final TextEditingController searchController;
  final HistoryFilter selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<HistoryFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, value, _) => TextField(
                  key: const Key('history_search_field'),
                  controller: searchController,
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari kode atau pengajuan',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('clear_history_search'),
                            tooltip: 'Hapus pencarian',
                            onPressed: onClearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    fillColor: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: HistoryFilter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = HistoryFilter.values[index];
                    final selected = filter == selectedFilter;
                    return ChoiceChip(
                      key: Key('history_filter_${filter.name}'),
                      selected: selected,
                      onSelected: (_) => onFilterSelected(filter),
                      showCheckmark: false,
                      label: Text(filter.label),
                      labelStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            color: selected
                                ? AppColors.primaryDeep
                                : AppColors.inkSoft,
                          ),
                      selectedColor: AppColors.primarySoft,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.55)
                            : AppColors.line,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.detailActionKey,
    required this.onDetail,
    super.key,
  });

  final HistoryEntry entry;
  final Key detailActionKey;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final typeStyle = HistoryTypeVisual.forType(entry.serviceType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isRead ? AppColors.surface : const Color(0xFFFBFEFF),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: entry.isRead
              ? AppColors.line
              : AppColors.primary.withValues(alpha: 0.42),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E6687),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: typeStyle.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  typeStyle.icon,
                  color: typeStyle.foreground,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.typeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: typeStyle.foreground),
                          ),
                        ),
                        if (!entry.isRead) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryStrong,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HistoryStatusBadge(status: entry.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (entry.compactSummary case final summary?) ...[
            const SizedBox(height: 5),
            Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formatHistoryDate(entry.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              InkWell(
                key: detailActionKey,
                onTap: onDetail,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detail',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primaryStrong),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primaryStrong,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.loading,
    required this.hasMore,
    required this.visible,
    required this.total,
  });

  final bool loading;
  final bool hasMore;
  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: Key('history_loading_more'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                )
              : Text(
                  hasMore
                      ? '$visible dari $total pengajuan'
                      : 'Semua history sudah ditampilkan',
                  key: const Key('history_pagination_status'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('history_skeleton'),
      children: List.generate(
        4,
        (index) => Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBlock(width: 43, height: 43, radius: 14),
                  SizedBox(width: 12),
                  Expanded(child: _SkeletonBlock(height: 12, radius: 6)),
                  SizedBox(width: 26),
                  _SkeletonBlock(width: 64, height: 27, radius: 14),
                ],
              ),
              SizedBox(height: 18),
              _SkeletonBlock(width: 210, height: 15, radius: 7),
              SizedBox(height: 10),
              _SkeletonBlock(height: 11, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.radius,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.primaryPale,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      key: const Key('history_error'),
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.coral,
      iconBackground: AppColors.coralSoft,
      title: 'History belum dapat dimuat',
      message: message,
      action: OutlinedButton.icon(
        key: const Key('retry_history'),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Coba lagi'),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({
    required this.allHistoryEmpty,
    required this.hasQuery,
    required this.filter,
    required this.onReset,
  });

  final bool allHistoryEmpty;
  final bool hasQuery;
  final HistoryFilter filter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final title = allHistoryEmpty
        ? 'Belum ada history'
        : hasQuery
        ? 'Tidak ada hasil yang sesuai'
        : 'Belum ada pengajuan ${filter.label}';
    final message = allHistoryEmpty
        ? 'Pengajuan layananmu akan tersusun rapi di sini.'
        : hasQuery
        ? 'Coba kata kunci lain atau ubah filter layanan.'
        : 'Pengajuan layanan ini belum tercatat pada akunmu.';
    return _StatePanel(
      key: const Key('history_empty'),
      icon: allHistoryEmpty
          ? Icons.history_toggle_off_rounded
          : Icons.search_off_rounded,
      iconColor: AppColors.primaryStrong,
      iconBackground: AppColors.primarySoft,
      title: title,
      message: message,
      action: allHistoryEmpty
          ? null
          : TextButton.icon(
              key: const Key('reset_history_filters'),
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset pencarian'),
            ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(23),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 17), action!],
          ],
        ),
      ),
    );
  }
}
