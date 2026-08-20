import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'damage_report_models.dart';

class DamageMediaSourceSheet extends StatelessWidget {
  const DamageMediaSourceSheet({
    super.key,
    required this.remainingSlots,
    required this.onSelected,
  });

  final int remainingSlots;
  final ValueChanged<DamageMediaSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
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
              'Tambahkan bukti',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              '$remainingSlots slot tersisa · maksimum 20 MB per file',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 17),
            _MediaSourceOption(
              key: const Key('source_camera_photo'),
              icon: Icons.photo_camera_outlined,
              title: 'Ambil Foto',
              subtitle: 'Gunakan kamera untuk memotret kerusakan',
              color: AppColors.primaryStrong,
              background: AppColors.primarySoft,
              onTap: () => onSelected(DamageMediaSource.cameraPhoto),
            ),
            const SizedBox(height: 10),
            _MediaSourceOption(
              key: const Key('source_camera_video'),
              icon: Icons.videocam_outlined,
              title: 'Rekam Video',
              subtitle: 'Rekam kondisi atau suara kerusakan',
              color: AppColors.coral,
              background: AppColors.coralSoft,
              onTap: () => onSelected(DamageMediaSource.cameraVideo),
            ),
            const SizedBox(height: 10),
            _MediaSourceOption(
              key: const Key('source_gallery'),
              icon: Icons.photo_library_outlined,
              title: 'Pilih dari Galeri',
              subtitle: 'Pilih foto atau video yang sudah tersedia',
              color: AppColors.lavender,
              background: AppColors.lavenderSoft,
              onTap: () => onSelected(DamageMediaSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaSourceOption extends StatelessWidget {
  const _MediaSourceOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
