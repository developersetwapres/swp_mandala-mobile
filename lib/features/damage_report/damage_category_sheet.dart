import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'damage_report_models.dart';

class DamageCategorySheet extends StatelessWidget {
  const DamageCategorySheet({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<DamageCategory> categories;
  final DamageCategory? selectedCategory;
  final ValueChanged<DamageCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Pilih kategori kerusakan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              'Lihat contoh item agar laporan masuk ke tim yang tepat.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 17),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CategoryOption(
                  category: category,
                  selected: category == selectedCategory,
                  onTap: () => onSelected(category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final DamageCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category.name) {
      'Tata Suara' => Icons.speaker_group_outlined,
      'Tata Udara' => Icons.air_rounded,
      _ => Icons.category_outlined,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPale : AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: selected ? AppColors.primaryStrong : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(
            'category_${category.name.toLowerCase().replaceAll(' ', '_')}',
          ),
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primarySoft
                        : AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primaryStrong, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected
                                ? AppColors.primaryStrong
                                : AppColors.line,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (category.examples.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Termasuk: ${category.examples.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primaryDeep,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
