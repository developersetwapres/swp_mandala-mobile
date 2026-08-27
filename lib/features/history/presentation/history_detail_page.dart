import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/media_url_resolver.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/history_entry.dart';
import 'history_presentation.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({required this.entry, super.key});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            key: const Key('history_detail_back'),
            tooltip: 'Kembali ke History',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Detail Pengajuan'),
          titleTextStyle: Theme.of(context).textTheme.titleMedium,
        ),
        body: CustomScrollView(
          key: const Key('history_detail_scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _RequestHero(entry: entry)),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RequestSnapshot(entry: entry),
                        ..._serviceSections(entry),
                        if (_hasRequesterInformation(entry))
                          _RequesterSection(entry: entry),
                        if (_additionalNote(entry) case final note?)
                          _DetailSection(
                            key: const Key('detail_additional_note'),
                            icon: Icons.sticky_note_2_outlined,
                            title: 'Catatan tambahan',
                            child: _NarrativeSurface(text: note),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _serviceSections(HistoryEntry entry) =>
      switch (entry.serviceType) {
        HistoryServiceType.officeSupply => [_OfficeSupplyDetail(entry: entry)],
        HistoryServiceType.meetingRoom => [_MeetingRoomDetail(entry: entry)],
        HistoryServiceType.damage => [_DamageDetail(entry: entry)],
        HistoryServiceType.unknown => [_GenericDetail(entry: entry)],
      };
}

class _RequestHero extends StatelessWidget {
  const _RequestHero({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final visual = HistoryTypeVisual.forType(entry.serviceType);
    return Container(
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
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: visual.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Icon(
                        visual.icon,
                        color: visual.foreground,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.typeLabel,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: visual.foreground),
                      ),
                    ),
                    HistoryStatusBadge(
                      key: const Key('history_detail_status'),
                      status: entry.status,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  entry.displayTitle,
                  key: const Key('history_detail_title'),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontSize: 25, height: 1.25),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _HeroChip(
                      key: const Key('history_detail_code'),
                      icon: Icons.tag_rounded,
                      label: entry.code,
                    ),
                    _HeroChip(
                      icon: Icons.schedule_rounded,
                      label: formatHistoryDate(entry.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.primaryDeep),
          ),
        ],
      ),
    );
  }
}

class _RequestSnapshot extends StatelessWidget {
  const _RequestSnapshot({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('history_detail_snapshot'),
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const _SnapshotIcon(
            icon: Icons.fact_check_outlined,
            color: AppColors.primaryStrong,
            background: AppColors.primarySoft,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permintaan tercatat',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'Diajukan ${formatHistoryDate(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotIcon extends StatelessWidget {
  const _SnapshotIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _OfficeSupplyDetail extends StatelessWidget {
  const _OfficeSupplyDetail({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (entry.supplyItems.isNotEmpty)
          _DetailSection(
            key: const Key('detail_atk_items'),
            icon: Icons.inventory_2_outlined,
            title: 'Daftar kebutuhan',
            subtitle: '${entry.supplyItems.length} barang diajukan',
            child: Column(
              children: entry.supplyItems.indexed
                  .map(
                    (item) => _SupplyItemTile(
                      item: item.$2,
                      index: item.$1,
                      showApproved:
                          item.$2.approved != null &&
                          !const {
                            'pending',
                            'waiting',
                          }.contains(entry.status.trim().toLowerCase()),
                      showDivider: item.$1 < entry.supplyItems.length - 1,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (_firstDistinct([entry.description]) case final text?)
          _DetailSection(
            key: const Key('detail_atk_description'),
            icon: Icons.notes_rounded,
            title: 'Keperluan pengajuan',
            child: _NarrativeSurface(text: text),
          ),
      ],
    );
  }
}

class _SupplyItemTile extends StatelessWidget {
  const _SupplyItemTile({
    required this.item,
    required this.index,
    required this.showApproved,
    required this.showDivider,
  });

  final HistorySupplyItem item;
  final int index;
  final bool showApproved;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final custom = item.id == null || item.status?.toLowerCase() == 'custom';
    final requested = [
      if (item.requested != null) item.requested.toString(),
      item.unit,
    ].whereType<String>().join(' ');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lavenderSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.lavender),
                ),
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
                            item.name,
                            key: Key('detail_atk_item_$index'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (custom)
                          const _TinyTag(
                            label: 'Lain-lain',
                            color: AppColors.lavender,
                            background: AppColors.lavenderSoft,
                          ),
                      ],
                    ),
                    if (requested.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Diminta $requested',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (showApproved) ...[
                      const SizedBox(height: 7),
                      _TinyTag(
                        label: 'Disetujui ${item.approved} ${item.unit ?? ''}'
                            .trim(),
                        color: AppColors.mint,
                        background: AppColors.mintSoft,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}

class _MeetingRoomDetail extends StatelessWidget {
  const _MeetingRoomDetail({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final purpose = _firstDistinct([entry.info, entry.description]);
    final hasRoomInformation =
        entry.room != null || _hasText(entry.subtitle) || _hasText(entry.time);
    final hasMeetingInformation =
        _hasText(entry.meetingType) ||
        entry.needsItSupport == true ||
        entry.isHybrid == true ||
        purpose != null;
    return Column(
      children: [
        if (hasRoomInformation)
          _DetailSection(
            key: const Key('detail_room_information'),
            icon: Icons.meeting_room_outlined,
            title: 'Ruang & jadwal',
            child: _TonalGroup(
              children: [
                if (_hasText(entry.room?.name))
                  _InformationRow(
                    icon: Icons.domain_outlined,
                    label: 'Ruangan',
                    value: entry.room!.name!,
                  ),
                if (_hasText(entry.room?.location))
                  _InformationRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi',
                    value: entry.room!.location!,
                  ),
                if (_hasText(entry.subtitle))
                  _InformationRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal penggunaan',
                    value: entry.subtitle!,
                  ),
                if (_hasText(entry.time))
                  _InformationRow(
                    icon: Icons.schedule_outlined,
                    label: 'Jam penggunaan',
                    value: entry.time!,
                  ),
              ],
            ),
          ),
        if (hasMeetingInformation)
          _DetailSection(
            key: const Key('detail_meeting_information'),
            icon: Icons.groups_2_outlined,
            title: 'Informasi rapat',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (purpose != null) _NarrativeSurface(text: purpose),
                if (_hasText(entry.meetingType)) ...[
                  if (purpose != null) const SizedBox(height: 13),
                  _InformationRow(
                    icon: Icons.people_alt_outlined,
                    label: 'Jenis rapat',
                    value: humanizeHistoryValue(entry.meetingType!),
                  ),
                ],
                if (entry.needsItSupport == true) ...[
                  const SizedBox(height: 12),
                  _FeatureNotice(
                    key: const Key('detail_it_support'),
                    icon: Icons.support_agent_rounded,
                    title: 'Dukungan IT diminta',
                    detail: entry.itSupportDetail,
                  ),
                ],
                if (entry.isHybrid == true) ...[
                  const SizedBox(height: 12),
                  _FeatureNotice(
                    key: const Key('detail_hybrid'),
                    icon: Icons.video_camera_front_outlined,
                    title: 'Mode Hybrid',
                    detail: entry.hybridDetail,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DamageDetail extends StatelessWidget {
  const _DamageDetail({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_hasText(entry.info) || _hasText(entry.description))
          _DetailSection(
            key: const Key('detail_damage_report'),
            icon: Icons.home_repair_service_outlined,
            title: 'Detail kerusakan',
            child: Column(
              children: [
                if (_hasText(entry.info))
                  _InformationRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi',
                    value: entry.info!,
                  ),
                if (_hasText(entry.info) && _hasText(entry.description))
                  const SizedBox(height: 13),
                if (_hasText(entry.description))
                  _NarrativeSurface(text: entry.description!),
              ],
            ),
          ),
        if (entry.category case final category?)
          _DetailSection(
            key: const Key('detail_damage_category'),
            icon: Icons.category_outlined,
            title: 'Kategori kerusakan',
            child: _DamageCategorySurface(category: category),
          ),
        if (entry.pictures.isNotEmpty)
          _DetailSection(
            key: const Key('detail_damage_attachments'),
            icon: Icons.photo_library_outlined,
            title: 'Lampiran',
            subtitle: '${entry.pictures.length} media dilampirkan',
            child: _AttachmentGallery(entry: entry),
          ),
      ],
    );
  }
}

class _DamageCategorySurface extends StatelessWidget {
  const _DamageCategorySurface({required this.category});

  final HistoryDamageCategory category;

  @override
  Widget build(BuildContext context) {
    return _TonalGroup(
      children: [
        if (_hasText(category.name))
          Text(category.name!, style: Theme.of(context).textTheme.titleMedium),
        if (_hasText(category.section)) ...[
          const SizedBox(height: 4),
          Text(category.section!, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (_hasText(category.damageCode)) ...[
          const SizedBox(height: 10),
          _TinyTag(
            label: category.damageCode!,
            color: AppColors.coral,
            background: AppColors.coralSoft,
          ),
        ],
        if (category.subcategories.isNotEmpty) ...[
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: category.subcategories
                .take(4)
                .map(
                  (item) => _TinyTag(
                    label: item,
                    color: AppColors.inkSoft,
                    background: AppColors.surface,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _GenericDetail extends StatelessWidget {
  const _GenericDetail({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = _firstDistinct([
      entry.info,
      entry.description,
      entry.subtitle,
    ]);
    if (text == null) return const SizedBox.shrink();
    return _DetailSection(
      icon: Icons.description_outlined,
      title: 'Informasi pengajuan',
      child: _NarrativeSurface(text: text),
    );
  }
}

class _RequesterSection extends StatelessWidget {
  const _RequesterSection({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final employee = entry.user?.employee;
    final organization = _firstDistinct([employee?.bureauName, entry.workUnit]);
    return _DetailSection(
      key: const Key('detail_requester'),
      icon: Icons.person_outline_rounded,
      title: 'Pemohon',
      child: _TonalGroup(
        children: [
          if (_hasText(employee?.name))
            _InformationRow(
              icon: Icons.badge_outlined,
              label: 'Nama',
              value: employee!.name!,
            ),
          if (organization != null)
            _InformationRow(
              icon: Icons.apartment_outlined,
              label: 'Unit kerja',
              value: organization,
            ),
          if (_hasText(entry.phone))
            _InformationRow(
              icon: Icons.phone_outlined,
              label: 'Kontak',
              value: entry.phone!,
            ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TonalGroup extends StatelessWidget {
  const _TonalGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primaryStrong),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrativeSurface extends StatelessWidget {
  const _NarrativeSurface({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _FeatureNotice extends StatelessWidget {
  const _FeatureNotice({
    required this.icon,
    required this.title,
    required this.detail,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mint, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (_hasText(detail)) ...[
                  const SizedBox(height: 3),
                  Text(detail!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontSize: 10.5),
      ),
    );
  }
}

class _AttachmentGallery extends StatelessWidget {
  const _AttachmentGallery({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView.separated(
        key: const Key('detail_attachment_gallery'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entry.pictures.length,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (context, index) => AspectRatio(
          aspectRatio: 1.22,
          child: Material(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(21),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('detail_attachment_$index'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      _AttachmentViewer(entry: entry, initialIndex: index),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: _mediaHeroTag(entry, index),
                    child: _RemoteAttachment(
                      url: entry.pictures[index],
                      index: index,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                    ),
                  ),
                  Positioned(
                    right: 9,
                    bottom: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${index + 1}/${entry.pictures.length}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteAttachment extends StatelessWidget {
  const _RemoteAttachment({
    required this.url,
    required this.index,
    required this.fit,
    this.cacheWidth,
  });

  final String url;
  final int index;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      MediaUrlResolver.resolve(url),
      key: Key('detail_attachment_image_$index'),
      fit: fit,
      cacheWidth: cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _AttachmentPlaceholder(
          key: Key('detail_attachment_loading_$index'),
          loading: true,
        );
      },
      errorBuilder: (context, error, stackTrace) => _AttachmentPlaceholder(
        key: Key('detail_attachment_error_$index'),
        loading: false,
      ),
    );
  }
}

class _AttachmentPlaceholder extends StatelessWidget {
  const _AttachmentPlaceholder({required this.loading, super.key});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryPale,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.inkMuted,
                    size: 30,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Media belum dapat dimuat',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class _AttachmentViewer extends StatefulWidget {
  const _AttachmentViewer({required this.entry, required this.initialIndex});

  final HistoryEntry entry;
  final int initialIndex;

  @override
  State<_AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<_AttachmentViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        key: const Key('attachment_viewer'),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.entry.pictures.length,
              onPageChanged: (value) => setState(() => _currentIndex = value),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: _mediaHeroTag(widget.entry, index),
                    child: _RemoteAttachment(
                      url: widget.entry.pictures[index],
                      index: index,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton.filled(
                      key: const Key('attachment_viewer_close'),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.entry.pictures.length}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _hasRequesterInformation(HistoryEntry entry) {
  final employee = entry.user?.employee;
  return _hasText(employee?.name) ||
      _hasText(employee?.bureauName) ||
      _hasText(entry.workUnit) ||
      _hasText(entry.phone);
}

String? _additionalNote(HistoryEntry entry) {
  final note = entry.notes?.trim();
  if (!_hasText(note)) return null;
  final existing = [
    entry.info,
    entry.description,
  ].whereType<String>().map((value) => value.trim().toLowerCase());
  return existing.contains(note!.toLowerCase()) ? null : note;
}

String? _firstDistinct(Iterable<String?> values) {
  final seen = <String>{};
  for (final value in values) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) continue;
    if (seen.add(clean.toLowerCase())) return clean;
  }
  return null;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _mediaHeroTag(HistoryEntry entry, int index) =>
    'history-media-${identityHashCode(entry)}-$index';
