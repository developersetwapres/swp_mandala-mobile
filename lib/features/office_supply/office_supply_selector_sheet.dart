import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'office_supply_models.dart';

class OfficeSupplySelectorSheet extends StatefulWidget {
  const OfficeSupplySelectorSheet({
    super.key,
    required this.supplies,
    required this.selectedMasterIds,
  });

  final List<OfficeSupply> supplies;
  final Set<String> selectedMasterIds;

  @override
  State<OfficeSupplySelectorSheet> createState() =>
      _OfficeSupplySelectorSheetState();
}

class _OfficeSupplySelectorSheetState extends State<OfficeSupplySelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OfficeSupply> get _visibleSupplies {
    if (_query.trim().isEmpty) return widget.supplies;
    final query = _query.toLowerCase().trim();
    return widget.supplies
        .where(
          (supply) =>
              supply.name.toLowerCase().contains(query) ||
              supply.description.toLowerCase().contains(query) ||
              (supply.unit?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        final visibleSupplies = _visibleSupplies;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pilih alat tulis',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Cari item lalu atur jumlah yang dibutuhkan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      key: const Key('supply_search_field'),
                      controller: _searchController,
                      autofocus: false,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Cari nama ATK atau satuan',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              Expanded(
                child: visibleSupplies.isEmpty
                    ? const _EmptySearchResult()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        itemCount: visibleSupplies.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final supply = visibleSupplies[index];
                          return _SupplyOption(
                            supply: supply,
                            selected: widget.selectedMasterIds.contains(
                              supply.id,
                            ),
                            onTap: () => Navigator.pop(context, supply),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupplyOption extends StatelessWidget {
  const _SupplyOption({
    required this.supply,
    required this.selected,
    required this.onTap,
  });

  final OfficeSupply supply;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = supply.isOther
        ? AppColors.lavender
        : AppColors.primaryStrong;
    final accentSoft = supply.isOther
        ? AppColors.lavenderSoft
        : AppColors.primarySoft;

    return Material(
      color: selected
          ? AppColors.mintSoft.withValues(alpha: 0.58)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('supply_${supply.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.mint : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: selected ? AppColors.mintSoft : accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : supply.icon,
                  color: selected ? AppColors.mint : accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supply.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      supply.isOther
                          ? supply.description
                          : '${supply.description} · ${supply.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Text(
                  'Sudah ditambahkan',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.mint, fontSize: 9),
                )
              else
                Icon(
                  supply.isOther
                      ? Icons.add_circle_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: accent,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'ATK belum ditemukan',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Coba kata kunci lain atau pilih Lain-Lain.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
