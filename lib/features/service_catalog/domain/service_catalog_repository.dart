import '../../damage_report/damage_report_models.dart';
import '../../meeting_room/meeting_room_models.dart';
import '../../office_supply/office_supply_models.dart';

abstract interface class ServiceCatalogRepository {
  Future<List<MeetingRoom>> getAvailableRooms({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  });

  Future<List<OfficeSupply>> getAvailableOfficeSupplies({
    bool forceRefresh = false,
  });

  Future<List<DamageCategory>> getDamageCategories({bool forceRefresh = false});
}
