import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/auth/domain/app_user.dart';
import 'package:swp_mandala_mobile/features/home/home_page.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_page_result.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_repository.dart';
import 'package:swp_mandala_mobile/features/damage_report/damage_report_models.dart';
import 'package:swp_mandala_mobile/features/meeting_room/meeting_room_models.dart';
import 'package:swp_mandala_mobile/features/office_supply/office_supply_models.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_catalog_repository.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_submission_failure.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_submission_models.dart';

const testUser = AppUser(
  id: 7,
  email: 'nadia.pratama@example.go.id',
  name: 'Nadia Pratama',
  unitKerja: 'Biro Umum',
);

class TestHistoryRepository implements HistoryRepository {
  TestHistoryRepository({
    List<HistoryEntry>? entries,
    this.error,
    this.response,
  }) : entries = entries ?? defaultHistory;

  final List<HistoryEntry> entries;
  final Object? error;
  final Future<List<HistoryEntry>>? response;
  int calls = 0;

  static final defaultHistory = [
    HistoryEntry.fromJson({
      'id': 'booking',
      'type': 'Ruangan Rapat',
      'is_read': 0,
      'code': 'RRT-0821-ABC',
      'title': 'Ruang Rapat Buton',
      'ruangans': {
        'id': 2,
        'nama_ruangan': 'Ruang Rapat Buton',
        'lokasi': 'Gedung 2, Lantai 3',
      },
      'info': 'Koordinasi program kerja',
      'subtitle': '21 Agustus 2026',
      'created_at': '2026-08-21T08:58:43.000000Z',
      'status': 'booked',
      'time': '09:00 - 11:00',
    }),
    HistoryEntry.fromJson({
      'id': 'supplies',
      'type': 'ATK',
      'is_read': 1,
      'code': 'ATK-0821-VPV',
      'title': '2 item',
      'info': 'Amplop Coklat 5 Buah, Pulpen 2 Pcs',
      'daftarkebutuhan': [
        {
          'id': 353,
          'name': 'Amplop Coklat',
          'satuan': 'Buah',
          'status': 'normal',
          'requested': 5,
          'approved': 0,
        },
      ],
      'created_at': '2026-08-20T04:30:00.000000Z',
      'status': 'pending',
    }),
    HistoryEntry.fromJson({
      'id': 'damage',
      'type': 'Kerusakan',
      'is_read': 1,
      'code': 'KRS-0820-ZZZ',
      'title': 'AC Ruang Rapat',
      'info': 'Gedung Sekretariat I Lantai 4',
      'deskripsi': 'AC tidak mengeluarkan udara dingin.',
      'kategori': {
        'id': 4,
        'kode_kerusakan': 'KRN-Q9HCF',
        'name': 'Tata Udara',
        'sub_kategori': ['AC', 'Kipas Angin'],
      },
      'picture': ['https://example.test/ac.jpg'],
      'created_at': 'malformed optional date',
      'status': 'completed',
    }),
  ];

  @override
  Future<List<HistoryEntry>> getHistory() async =>
      (await getHistoryPage()).entries;

  @override
  Future<HistoryPageResult> getHistoryPage({
    int page = 1,
    String search = '',
  }) async {
    calls += 1;
    if (error case final value?) throw value;
    final resolvedEntries = response != null ? await response! : entries;
    final query = search.trim().toLowerCase();
    final filtered = query.isEmpty
        ? resolvedEntries
        : resolvedEntries
              .where((entry) => entry.searchText.contains(query))
              .toList(growable: false);
    const perPage = 5;
    final lastPage = filtered.isEmpty ? 1 : (filtered.length / perPage).ceil();
    final safePage = page.clamp(1, lastPage) as int;
    final start = (safePage - 1) * perPage;
    final pageEntries = filtered
        .skip(start)
        .take(perPage)
        .toList(growable: false);
    return HistoryPageResult(
      entries: pageEntries,
      currentPage: safePage,
      lastPage: lastPage,
      total: filtered.length,
      from: pageEntries.isEmpty ? null : start + 1,
      to: pageEntries.isEmpty ? null : start + pageEntries.length,
      pageLinks: List.generate(
        lastPage,
        (index) => HistoryPageLink(
          page: index + 1,
          active: index + 1 == safePage,
        ),
      ),
      previousPage: safePage > 1 ? safePage - 1 : null,
      nextPage: safePage < lastPage ? safePage + 1 : null,
    );
  }
}

class TestServiceCatalogRepository implements ServiceCatalogRepository {
  TestServiceCatalogRepository({
    this.rooms = defaultRooms,
    this.supplies = defaultSupplies,
    this.categories = defaultCategories,
    this.roomError,
    this.supplyError,
    this.categoryError,
    this.roomSubmitError,
    this.supplySubmitError,
    this.damageSubmitError,
    this.roomSubmitFuture,
    this.supplySubmitFuture,
    this.damageSubmitFuture,
  });

  final List<MeetingRoom> rooms;
  final List<OfficeSupply> supplies;
  final List<DamageCategory> categories;
  final Object? roomError;
  final Object? supplyError;
  final Object? categoryError;
  final ServiceSubmissionFailure? roomSubmitError;
  final ServiceSubmissionFailure? supplySubmitError;
  final ServiceSubmissionFailure? damageSubmitError;
  final Future<ServiceSubmitResponse>? roomSubmitFuture;
  final Future<ServiceSubmitResponse>? supplySubmitFuture;
  final Future<ServiceSubmitResponse>? damageSubmitFuture;
  int roomCalls = 0;
  int supplyCalls = 0;
  int categoryCalls = 0;
  int roomSubmitCalls = 0;
  int supplySubmitCalls = 0;
  int damageSubmitCalls = 0;
  RoomBookingSubmission? submittedRoom;
  OfficeSupplySubmission? submittedSupply;
  DamageReportSubmission? submittedDamage;

  static const defaultRooms = [
    MeetingRoom(
      id: 'buton',
      name: 'Ruang Rapat Buton',
      code: 'RPT-BUTON',
      location: 'Gedung 2, Lantai 3',
      capacity: '10',
      maximumCapacityLabel: '14',
      maximumCapacity: 14,
      isAvailable: true,
      islandName: 'Pulau Buton',
      philosophy: 'Ruang kolaborasi yang fokus dan hangat.',
      bookedSlots: [],
      bookedByBureaus: [],
      facilities: ['tv-led'],
    ),
    MeetingRoom(
      id: 'bali',
      name: 'Ruang Rapat Bali',
      code: 'RPT-BALI',
      location: 'Gedung 1, Lantai 2',
      capacity: '8',
      maximumCapacityLabel: '10',
      maximumCapacity: 10,
      isAvailable: false,
      islandName: 'Pulau Bali',
      philosophy: 'Ruang yang membawa semangat harmoni.',
      bookedSlots: ['09.00–12.00'],
      bookedByBureaus: ['Biro Umum'],
      facilities: [],
    ),
  ];

  static const defaultSupplies = [
    OfficeSupply(
      id: 'pen',
      name: 'Pulpen',
      unit: 'Pcs',
      icon: Icons.edit_rounded,
      description: 'ALAT TULIS',
      categoryId: 1,
      categoryName: 'ALAT TULIS',
    ),
    OfficeSupply(
      id: 'paper_a4',
      name: 'Kertas A4',
      unit: 'Rim',
      icon: Icons.description_outlined,
      description: 'KERTAS',
      categoryId: 2,
      categoryName: 'KERTAS',
    ),
    OfficeSupply(
      id: 'paper_f4',
      name: 'Kertas F4',
      unit: 'Rim',
      icon: Icons.description_outlined,
      description: 'KERTAS',
      categoryId: 2,
      categoryName: 'KERTAS',
    ),
    OfficeSupply(
      id: 'binder_clip',
      name: 'Binder Clip',
      unit: 'Box',
      icon: Icons.inventory_2_outlined,
      description: 'PENJEPIT',
      categoryId: 3,
      categoryName: 'PENJEPIT',
    ),
  ];

  static const defaultCategories = [
    DamageCategory(
      id: 1,
      code: 'KRN-SOUND',
      name: 'Tata Suara',
      examples: ['Mic Conference', 'Public Address'],
    ),
    DamageCategory(
      id: 2,
      code: 'KRN-AIR',
      name: 'Tata Udara',
      examples: ['AC', 'Exhaust Fan', 'Kipas Angin'],
    ),
  ];

  @override
  Future<List<MeetingRoom>> getAvailableRooms({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    roomCalls += 1;
    if (roomError case final error?) throw error;
    return rooms;
  }

  @override
  Future<List<OfficeSupply>> getAvailableOfficeSupplies({
    bool forceRefresh = false,
  }) async {
    supplyCalls += 1;
    if (supplyError case final error?) throw error;
    return supplies;
  }

  @override
  Future<List<DamageCategory>> getDamageCategories({
    bool forceRefresh = false,
  }) async {
    categoryCalls += 1;
    if (categoryError case final error?) throw error;
    return categories;
  }

  @override
  Future<ServiceSubmitResponse> submitRoomBooking(
    RoomBookingSubmission submission,
  ) async {
    roomSubmitCalls += 1;
    submittedRoom = submission;
    if (roomSubmitError case final error?) throw error;
    if (roomSubmitFuture case final future?) return future;
    return const ServiceSubmitResponse(
      message: 'Pemesanan Ruang Rapat Buton berhasil diajukan.',
    );
  }

  @override
  Future<ServiceSubmitResponse> submitOfficeSupplyRequest(
    OfficeSupplySubmission submission,
  ) async {
    supplySubmitCalls += 1;
    submittedSupply = submission;
    if (supplySubmitError case final error?) throw error;
    if (supplySubmitFuture case final future?) return future;
    return const ServiceSubmitResponse(
      message: 'Permintaan ATK berhasil diajukan.',
    );
  }

  @override
  Future<ServiceSubmitResponse> submitDamageReport(
    DamageReportSubmission submission,
  ) async {
    damageSubmitCalls += 1;
    submittedDamage = submission;
    if (damageSubmitError case final error?) throw error;
    if (damageSubmitFuture case final future?) return future;
    return const ServiceSubmitResponse(
      message: 'Laporan kerusakan berhasil dikirim.',
    );
  }
}

Widget testApp({required Widget home}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  );
}

Widget homeTestApp({
  TestServiceCatalogRepository? repository,
  TestHistoryRepository? historyRepository,
}) => testApp(
  home: HomePage(
    user: testUser,
    serviceCatalogRepository: repository ?? TestServiceCatalogRepository(),
    historyRepository: historyRepository ?? TestHistoryRepository(),
  ),
);
