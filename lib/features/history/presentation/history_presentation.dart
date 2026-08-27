import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/history_entry.dart';

class HistoryTypeVisual {
  const HistoryTypeVisual(this.icon, this.foreground, this.background);

  final IconData icon;
  final Color foreground;
  final Color background;

  factory HistoryTypeVisual.forType(HistoryServiceType type) => switch (type) {
    HistoryServiceType.meetingRoom => const HistoryTypeVisual(
      Icons.meeting_room_outlined,
      AppColors.primaryStrong,
      AppColors.primarySoft,
    ),
    HistoryServiceType.officeSupply => const HistoryTypeVisual(
      Icons.edit_note_rounded,
      AppColors.lavender,
      AppColors.lavenderSoft,
    ),
    HistoryServiceType.damage => const HistoryTypeVisual(
      Icons.home_repair_service_outlined,
      AppColors.coral,
      AppColors.coralSoft,
    ),
    HistoryServiceType.unknown => const HistoryTypeVisual(
      Icons.assignment_outlined,
      AppColors.inkSoft,
      AppColors.primaryPale,
    ),
  };
}

class HistoryStatusVisual {
  const HistoryStatusVisual(this.foreground, this.background);

  final Color foreground;
  final Color background;

  factory HistoryStatusVisual.from(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'pending':
      case 'waiting':
      case 'diproses':
        return const HistoryStatusVisual(AppColors.amber, AppColors.amberSoft);
      case 'booked':
        return const HistoryStatusVisual(
          AppColors.primaryDeep,
          AppColors.primarySoft,
        );
      case 'approved':
      case 'completed':
      case 'selesai':
        return const HistoryStatusVisual(AppColors.mint, AppColors.mintSoft);
      case 'rejected':
      case 'cancelled':
      case 'ditolak':
        return const HistoryStatusVisual(AppColors.coral, AppColors.coralSoft);
      default:
        return const HistoryStatusVisual(
          AppColors.inkSoft,
          AppColors.primaryPale,
        );
    }
  }
}

class HistoryStatusBadge extends StatelessWidget {
  const HistoryStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final visual = HistoryStatusVisual.from(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        humanizeHistoryValue(status),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: visual.foreground, fontSize: 10.5),
      ),
    );
  }
}

String formatHistoryDate(DateTime? value, {bool includeTime = true}) {
  if (value == null) return 'Tanggal tidak tersedia';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final local = value.toLocal();
  final date = '${local.day} ${months[local.month - 1]} ${local.year}';
  if (!includeTime) return date;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$date · $hour:$minute';
}

String humanizeHistoryValue(String raw) {
  final clean = raw.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (clean.isEmpty || clean.toLowerCase() == 'unknown') return 'Lainnya';
  return clean
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
