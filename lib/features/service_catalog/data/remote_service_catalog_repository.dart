// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../damage_report/damage_report_models.dart';
import '../../meeting_room/meeting_room_models.dart';
import '../../office_supply/office_supply_models.dart';
import '../domain/service_catalog_failure.dart';
import '../domain/service_catalog_repository.dart';

class RemoteServiceCatalogRepository implements ServiceCatalogRepository {
  RemoteServiceCatalogRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  List<OfficeSupply>? _officeSupplyCache;
  List<DamageCategory>? _damageCategoryCache;
  Future<List<OfficeSupply>>? _officeSupplyRequest;
  Future<List<DamageCategory>>? _damageCategoryRequest;

  @override
  Future<List<MeetingRoom>> getAvailableRooms({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    try {
      final payload = await _apiClient.get(
        '/available-rooms',
        authenticated: true,
        queryParameters: {
          'tanggal': _date(date),
          'jam_mulai': _time(startHour, startMinute),
          'jam_selesai': _time(endHour, endMinute),
        },
      );
      return _parseList(
        payload: payload,
        key: 'availableRoom',
        parser: MeetingRoom.fromJson,
      );
    } catch (error) {
      throw _mapFailure(error, 'Data ruangan belum dapat dimuat.');
    }
  }

  @override
  Future<List<OfficeSupply>> getAvailableOfficeSupplies({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _officeSupplyCache != null) {
      return Future.value(_officeSupplyCache!);
    }
    if (_officeSupplyRequest != null) return _officeSupplyRequest!;
    final request = _loadOfficeSupplies();
    _officeSupplyRequest = request;
    return request.whenComplete(() => _officeSupplyRequest = null);
  }

  Future<List<OfficeSupply>> _loadOfficeSupplies() async {
    try {
      final payload = await _apiClient.get(
        '/available-atk',
        authenticated: true,
      );
      final items = _parseList(
        payload: payload,
        key: 'availableATK',
        parser: OfficeSupply.fromJson,
      );
      _officeSupplyCache = items;
      return items;
    } catch (error) {
      throw _mapFailure(error, 'Daftar ATK belum dapat dimuat.');
    }
  }

  @override
  Future<List<DamageCategory>> getDamageCategories({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _damageCategoryCache != null) {
      return Future.value(_damageCategoryCache!);
    }
    if (_damageCategoryRequest != null) return _damageCategoryRequest!;
    final request = _loadDamageCategories();
    _damageCategoryRequest = request;
    return request.whenComplete(() => _damageCategoryRequest = null);
  }

  Future<List<DamageCategory>> _loadDamageCategories() async {
    try {
      final payload = await _apiClient.get(
        '/available-kerusakan-sarpras',
        authenticated: true,
      );
      final items = _parseList(
        payload: payload,
        key: 'availableKategoriKerusakan',
        parser: DamageCategory.fromJson,
      );
      _damageCategoryCache = items;
      return items;
    } catch (error) {
      throw _mapFailure(error, 'Kategori kerusakan belum dapat dimuat.');
    }
  }

  List<T> _parseList<T>({
    required Map<String, dynamic> payload,
    required String key,
    required T Function(Map<String, dynamic>) parser,
  }) {
    final data = payload['data'];
    if (data is! Map<String, dynamic> || data[key] is! List) {
      throw const FormatException('Invalid service catalog payload.');
    }
    final rawItems = data[key] as List;
    final parsed = <T>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) continue;
      try {
        parsed.add(parser(rawItem));
      } on FormatException {
        // A single malformed record must not crash an otherwise usable list.
      }
    }
    if (rawItems.isNotEmpty && parsed.isEmpty) {
      throw const FormatException('No valid service catalog records.');
    }
    return List.unmodifiable(parsed);
  }

  ServiceCatalogFailure _mapFailure(Object error, String fallback) {
    if (error is ServiceCatalogFailure) return error;
    if (error is ApiConnectionException) {
      return const ServiceCatalogFailure(
        ServiceCatalogFailureType.connection,
        'Tidak dapat terhubung ke server. Periksa koneksi dan coba lagi.',
      );
    }
    if (error is ApiException && error.isUnauthorized) {
      return const ServiceCatalogFailure(
        ServiceCatalogFailureType.unauthorized,
        'Sesi telah berakhir. Silakan masuk kembali.',
      );
    }
    if (error is FormatException) {
      return const ServiceCatalogFailure(
        ServiceCatalogFailureType.invalidResponse,
        'Data dari server belum dapat diproses.',
      );
    }
    return ServiceCatalogFailure(ServiceCatalogFailureType.server, fallback);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}
