import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'home_models.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<ServiceItem> _services = [
    ServiceItem(
      name: 'Pemesanan Ruang Rapat',
      extension: 'Ext. 110',
      icon: Icons.meeting_room_outlined,
      color: AppColors.primaryStrong,
      softColor: AppColors.primarySoft,
    ),
    ServiceItem(
      name: 'Laporan Kerusakan Sarpras',
      extension: 'Ext. 120',
      icon: Icons.home_repair_service_outlined,
      color: AppColors.coral,
      softColor: AppColors.coralSoft,
    ),
    ServiceItem(
      name: 'Permintaan ATK',
      extension: 'Ext. 130',
      icon: Icons.edit_note_rounded,
      color: AppColors.lavender,
      softColor: AppColors.lavenderSoft,
    ),
    ServiceItem(
      name: 'Permintaan Kendaraan',
      extension: 'Ext. 140',
      icon: Icons.directions_car_filled_outlined,
      color: AppColors.mint,
      softColor: AppColors.mintSoft,
    ),
  ];

  static const List<ActivityItem> _activities = [
    ActivityItem(
      code: 'RRG-2026-001',
      date: '19 Agustus 2026',
      service: 'Pemesanan Ruang Rapat',
      title: 'Koordinasi program kerja',
      summary: 'Ruang Cendana · 09.00–11.00',
      status: 'Dipesan',
      statusColor: AppColors.primaryDeep,
      statusBackground: AppColors.primarySoft,
      icon: Icons.meeting_room_outlined,
    ),
    ActivityItem(
      code: 'ATK-2026-014',
      date: '16 Agustus 2026',
      service: 'Permintaan Alat Tulis Kantor',
      title: 'Keperluan administrasi bulanan',
      summary: 'Paket perlengkapan operasional',
      status: 'Diproses',
      statusColor: AppColors.amber,
      statusBackground: AppColors.amberSoft,
      icon: Icons.edit_note_rounded,
    ),
    ActivityItem(
      code: 'SRP-2026-009',
      date: '14 Agustus 2026',
      service: 'Laporan Kerusakan Sarpras',
      title: 'Lampu ruang arsip',
      summary: 'Pencahayaan tidak menyala sejak pagi',
      status: 'Selesai',
      statusColor: AppColors.mint,
      statusBackground: AppColors.mintSoft,
      icon: Icons.home_repair_service_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _WelcomeHero(onContact: () => _contactHelpdesk(context)),
            ),
            SliverToBoxAdapter(
              child: _PageContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const _SectionHeader(
                      title: 'Layanan',
                      subtitle: 'Pilih kebutuhanmu dengan cepat',
                      trailing: 'Geser untuk lainnya',
                    ),
                    const SizedBox(height: 16),
                    _ServiceCarousel(
                      services: _services,
                      onSelected: (service) => _selectService(context, service),
                    ),
                    const SizedBox(height: 34),
                    const _SectionHeader(
                      title: 'Aktivitas terbaru',
                      subtitle: 'Ringkasan permintaan terakhirmu',
                    ),
                    const SizedBox(height: 16),
                    ..._activities.indexed.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.$1 == _activities.length - 1 ? 0 : 12,
                        ),
                        child: _ActivityCard(activity: entry.$2),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactHelpdesk(BuildContext context) {
    _showMessage(context, 'Menghubungkan ke Helpdesk Mandala…');
  }

  void _selectService(BuildContext context, ServiceItem service) {
    _showMessage(context, '${service.name} dipilih');
  }

  void _showMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1FAFF), Color(0xFFC9EDFD)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          children: [
            const Positioned(
              top: -68,
              right: -48,
              child: _DecorativeCircle(size: 180, color: Color(0x3854BDF2)),
            ),
            const Positioned(
              top: 126,
              left: -36,
              child: _DecorativeCircle(size: 92, color: Color(0x2BFFFFFF)),
            ),
            _PageContent(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, topInset + 16, 0, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileGreeting(),
                    const SizedBox(height: 30),
                    Text(
                      'Ada yang bisa\nkami bantu?',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Urus kebutuhan kantor dengan lebih mudah.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDeep.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _HelpdeskCard(onContact: onContact),
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _ProfileGreeting extends StatelessWidget {
  const _ProfileGreeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          image: true,
          label: 'Avatar Nadia Pratama',
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryStrong],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2450AEDA),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              'NP',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.white, letterSpacing: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat pagi,',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryDeep.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Nadia Pratama',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Aktif',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.primaryDeep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpdeskCard extends StatelessWidget {
  const _HelpdeskCard({required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x174187A8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryStrong,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Helpdesk Mandala',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '(021) 555 0188',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primaryStrong,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const Key('contact_helpdesk'),
              onTap: onContact,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hubungi',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.primaryStrong, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceCarousel extends StatelessWidget {
  const _ServiceCarousel({required this.services, required this.onSelected});

  final List<ServiceItem> services;
  final ValueChanged<ServiceItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 360
            ? constraints.maxWidth * 0.72
            : 178.0;

        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: services.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final service = services[index];
              return SizedBox(
                width: itemWidth,
                child: _ServiceCard(
                  service: service,
                  onTap: () => onSelected(service),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.82)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C1E6687),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: service.softColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(service.icon, color: service.color, size: 24),
              ),
              const Spacer(),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(height: 1.3),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.extension,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: service.color),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: service.softColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: service.color,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: activity.statusBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  activity.icon,
                  color: activity.statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.code,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 13, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: activity.statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activity.status,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: activity.statusColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activity.service,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            activity.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}
