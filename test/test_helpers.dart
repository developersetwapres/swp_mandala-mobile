import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/auth/domain/app_user.dart';
import 'package:swp_mandala_mobile/features/home/home_page.dart';
import 'package:swp_mandala_mobile/features/damage_report/damage_report_models.dart';
import 'package:swp_mandala_mobile/features/meeting_room/meeting_room_models.dart';
import 'package:swp_mandala_mobile/features/office_supply/office_supply_models.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_catalog_repository.dart';

const testUser = AppUser(
  id: 7,
  email: 'nadia.pratama@example.go.id',
  name: 'Nadia Pratama',
  unitKerja: 'Biro Umum',
);

class TestServiceCatalogRepository implements ServiceCatalogRepository {
  TestServiceCatalogRepository({
    this.rooms = defaultRooms,
    this.supplies = defaultSupplies,
    this.categories = defaultCategories,
    this.roomError,
    this.supplyError,
    this.categoryError,
  });

  final List<MeetingRoom> rooms;
  final List<OfficeSupply> supplies;
  final List<DamageCategory> categories;
  final Object? roomError;
  final Object? supplyError;
  final Object? categoryError;
  int roomCalls = 0;
  int supplyCalls = 0;
  int categoryCalls = 0;

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

Widget homeTestApp({TestServiceCatalogRepository? repository}) => testApp(
  home: HomePage(
    user: testUser,
    serviceCatalogRepository: repository ?? TestServiceCatalogRepository(),
  ),
);
