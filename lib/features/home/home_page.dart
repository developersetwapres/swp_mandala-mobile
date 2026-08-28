import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/auth_scope.dart';
import '../auth/presentation/profile_page.dart';
import '../damage_report/damage_report_page.dart';
import '../history/domain/history_entry.dart';
import '../history/domain/history_failure.dart';
import '../history/domain/history_repository.dart';
import '../history/presentation/history_page.dart';
import '../history/presentation/history_supply_presentation.dart';
import '../meeting_room/meeting_room_booking_page.dart';
import '../office_supply/office_supply_request_page.dart';
import '../service_catalog/domain/service_catalog_repository.dart';
import 'home_models.dart';
import 'primary_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.user,
    required this.serviceCatalogRepository,
    required this.historyRepository,
    super.key,
  });

  final AppUser user;
  final ServiceCatalogRepository serviceCatalogRepository;
  final HistoryRepository historyRepository;

  @override
  State<HomePage> createState() => _HomePageState();

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
}

class _HomePageState extends State<HomePage> {
  List<ActivityItem> _recentActivities = const [];
  bool _loadingActivities = true;
  String? _activitiesError;

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
  }

  Future<void> _loadRecentActivities() async {
    if (mounted) {
      setState(() {
        _loadingActivities = true;
        _activitiesError = null;
      });
    }
    try {
      final history = await widget.historyRepository.getHistory();
      final sorted = history.indexed.toList()
        ..sort((left, right) {
          final leftDate = left.$2.createdAt;
          final rightDate = right.$2.createdAt;
          if (leftDate == null && rightDate == null) {
            return left.$1.compareTo(right.$1);
          }
          if (leftDate == null) return 1;
          if (rightDate == null) return -1;
          return rightDate.compareTo(leftDate);
        });
      if (!mounted) return;
      setState(() {
        _recentActivities = sorted
            .take(3)
            .map((item) => _activityFromHistory(item.$2))
            .toList(growable: false);
      });
    } on HistoryFailure catch (failure) {
      if (!mounted) return;
      if (failure.type == HistoryFailureType.unauthorized) {
        await AuthScope.of(context).logout();
        return;
      }
      setState(() => _activitiesError = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _activitiesError =
              'Aktivitas terbaru belum dapat dimuat. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingActivities = false);
    }
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
        body: RefreshIndicator(
          onRefresh: _loadRecentActivities,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _WelcomeHero(
                  user: widget.user,
                  onContact: () => _contactHelpdesk(context),
                ),
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
                        services: HomePage._services,
                        onSelected: (service) =>
                            _selectService(context, service),
                      ),
                      const SizedBox(height: 34),
                      const _SectionHeader(
                        title: 'Aktivitas terbaru',
                        subtitle: 'Ringkasan permintaan terakhirmu',
                      ),
                      const SizedBox(height: 16),
                      _RecentActivities(
                        activities: _recentActivities,
                        loading: _loadingActivities,
                        error: _activitiesError,
                        onRetry: _loadRecentActivities,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PrimaryNavigationBar(
          selectedIndex: 0,
          onSelected: (index) {
            if (index == 1) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      HistoryPage(repository: widget.historyRepository),
                ),
              );
            } else if (index == 2) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ProfilePage(user: widget.user),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _contactHelpdesk(BuildContext context) {
    _showMessage(context, 'Menghubungkan ke Helpdesk Mandala…');
  }

  Future<void> _selectService(BuildContext context, ServiceItem service) async {
    String? successMessage;
    if (service.name == 'Pemesanan Ruang Rapat') {
      successMessage = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (context) => MeetingRoomBookingPage(
            user: widget.user,
            repository: widget.serviceCatalogRepository,
          ),
        ),
      );
    } else if (service.name == 'Laporan Kerusakan Sarpras') {
      successMessage = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (context) => DamageReportPage(
            user: widget.user,
            repository: widget.serviceCatalogRepository,
          ),
        ),
      );
    } else if (service.name == 'Permintaan ATK') {
      successMessage = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (context) => OfficeSupplyRequestPage(
            user: widget.user,
            repository: widget.serviceCatalogRepository,
          ),
        ),
      );
    } else {
      _showMessage(context, '${service.name} dipilih');
    }
    if (!context.mounted || successMessage == null) return;
    _showMessage(context, successMessage);
    await _loadRecentActivities();
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
  const _WelcomeHero({required this.user, required this.onContact});

  final AppUser user;
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
                    _ProfileGreeting(user: user),
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
  const _ProfileGreeting({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          image: true,
          label: 'Avatar ${user.name}',
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
              user.initials,
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
                user.name,
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
                key: Key('service_$index'),
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

class _RecentActivities extends StatelessWidget {
  const _RecentActivities({
    required this.activities,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<ActivityItem> activities;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(
            key: Key('recent-activities-loading'),
            strokeWidth: 2.4,
          ),
        ),
      );
    }
    if (error != null && activities.isEmpty) {
      return Container(
        key: const Key('recent-activities-error'),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.coral),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (activities.isEmpty) {
      return Container(
        key: const Key('recent-activities-empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada aktivitas layanan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    return Column(
      key: const Key('recent-activities-list'),
      children: activities.indexed
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 == activities.length - 1 ? 0 : 12,
              ),
              child: _ActivityCard(activity: entry.$2),
            ),
          )
          .toList(growable: false),
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

ActivityItem _activityFromHistory(HistoryEntry entry) {
  final statusStyle = _ActivityStatusStyle.from(entry.status);
  return ActivityItem(
    code: entry.code,
    date: _formatActivityDate(entry.createdAt),
    service: _serviceLabel(entry),
    title: historyDisplayTitle(entry),
    summary: entry.compactSummary ?? 'Detail pengajuan tidak tersedia.',
    status: _humanizeActivityStatus(entry.status),
    statusColor: statusStyle.foreground,
    statusBackground: statusStyle.background,
    icon: switch (entry.serviceType) {
      HistoryServiceType.meetingRoom => Icons.meeting_room_outlined,
      HistoryServiceType.officeSupply => Icons.edit_note_rounded,
      HistoryServiceType.damage => Icons.home_repair_service_outlined,
      HistoryServiceType.unknown => Icons.assignment_outlined,
    },
  );
}

String _serviceLabel(HistoryEntry entry) => switch (entry.serviceType) {
  HistoryServiceType.meetingRoom => 'Pemesanan Ruang Rapat',
  HistoryServiceType.officeSupply => 'Permintaan Alat Tulis Kantor',
  HistoryServiceType.damage => 'Laporan Kerusakan Sarpras',
  HistoryServiceType.unknown => entry.typeLabel,
};

class _ActivityStatusStyle {
  const _ActivityStatusStyle(this.foreground, this.background);

  final Color foreground;
  final Color background;

  factory _ActivityStatusStyle.from(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'pending':
      case 'waiting':
      case 'diproses':
        return const _ActivityStatusStyle(AppColors.amber, AppColors.amberSoft);
      case 'booked':
        return const _ActivityStatusStyle(
          AppColors.primaryDeep,
          AppColors.primarySoft,
        );
      case 'approved':
      case 'completed':
      case 'selesai':
        return const _ActivityStatusStyle(AppColors.mint, AppColors.mintSoft);
      case 'rejected':
      case 'cancelled':
      case 'ditolak':
        return const _ActivityStatusStyle(AppColors.coral, AppColors.coralSoft);
      default:
        return const _ActivityStatusStyle(
          AppColors.inkSoft,
          AppColors.primaryPale,
        );
    }
  }
}

String _formatActivityDate(DateTime? value) {
  if (value == null) return 'Tanggal tidak tersedia';
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _humanizeActivityStatus(String raw) {
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
