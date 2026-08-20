import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'meeting_room_models.dart';

class RoomDetailSheet extends StatelessWidget {
  const RoomDetailSheet({super.key, required this.room});

  final MeetingRoom room;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Detail Ruangan',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                sliver: SliverList.list(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 1.55,
                        child: _RoomImage(
                          url: room.imageUrl,
                          fallbackAsset: 'assets/images/meeting_room.jpg',
                          semanticLabel: 'Foto ${room.name}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.primaryStrong,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      room.location,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _AvailabilityBadge(isAvailable: room.isAvailable),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _FactTile(
                            icon: Icons.groups_2_outlined,
                            label: 'Kapasitas nyaman',
                            value: '${room.capacity} orang',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FactTile(
                            icon: Icons.group_add_outlined,
                            label: 'Kapasitas maksimum',
                            value: '${room.maximumCapacityLabel} orang',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Cerita di balik nama',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Setiap ruang membawa semangat pulau Indonesia.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 2.15,
                            child: _RoomImage(
                              url: room.descriptionImageUrl,
                              fallbackAsset: 'assets/images/island.jpg',
                              semanticLabel: 'Foto ${room.islandName}',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(17),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.islandName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 7),
                                if (room.philosophy.isNotEmpty)
                                  Text(
                                    room.philosophy,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (room.facilities.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Fasilitas ruangan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: room.facilities
                            .map(
                              (facility) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  facility.replaceAll('-', ' '),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: AppColors.primaryDeep),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({
    required this.url,
    required this.fallbackAsset,
    required this.semanticLabel,
  });

  final String? url;
  final String fallbackAsset;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: AppColors.primaryPale,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (context, error, stackTrace) => Image.asset(
        fallbackAsset,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final foreground = isAvailable ? AppColors.mint : AppColors.coral;
    final background = isAvailable ? AppColors.mintSoft : AppColors.coralSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : 'Telah Dipesan',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground, fontSize: 11),
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryStrong, size: 21),
          const SizedBox(height: 13),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
