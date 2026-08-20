import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swp_mandala_mobile/core/network/api_client.dart';
import 'package:swp_mandala_mobile/core/storage/token_storage.dart';
import 'package:swp_mandala_mobile/features/service_catalog/data/remote_service_catalog_repository.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_catalog_failure.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'stored-token';

  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;
}

RemoteServiceCatalogRepository _repository(
  Future<http.Response> Function(http.Request) handler,
) {
  final storage = _MemoryTokenStorage();
  return RemoteServiceCatalogRepository(
    apiClient: ApiClient(
      baseUrl: 'http://src.test/api',
      tokenStorage: storage,
      client: MockClient(handler),
    ),
  );
}

void main() {
  test(
    'rooms map every API field and send encoded schedule parameters',
    () async {
      final repository = _repository((request) async {
        expect(request.headers['Authorization'], 'Bearer stored-token');
        expect(request.url.path, '/api/available-rooms');
        expect(request.url.queryParameters, {
          'tanggal': '2026-08-20',
          'jam_mulai': '08:00',
          'jam_selesai': '10:00',
        });
        return http.Response(
          jsonEncode({
            'data': {
              'availableRoom': [
                {
                  'id': 'RPT-ISYWN',
                  'nama_ruangan': 'Ruang Rapat Enggano',
                  'kode_ruangan': 'RPT-ISYWN',
                  'kapasitas': '34+1',
                  'kapasitas_max': '50+1',
                  'lokasi': 'Gedung Sekretariat II Lantai 1',
                  'status': 'booked',
                  'bookedSlots': ['09:00 - 15:00', '16:00 - 17:00'],
                  'image': 'http://src.test/files/room.jpg',
                  'image_desc': 'http://src.test/files/island.png',
                  'lokasi_desc': 'Pulau Enggano, Bengkulu',
                  'deskripsi': 'Permata terluar Indonesia.',
                  'facilities': ['tv-led', 'kamera'],
                  'bookedByBiro': ['Biro A', 'Biro B'],
                },
              ],
            },
          }),
          200,
        );
      });

      final rooms = await repository.getAvailableRooms(
        date: DateTime(2026, 8, 20),
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
      );

      final room = rooms.single;
      expect(room.id, 'RPT-ISYWN');
      expect(room.capacity, '34+1');
      expect(room.maximumCapacityLabel, '50+1');
      expect(room.maximumCapacity, 51);
      expect(room.isAvailable, isFalse);
      expect(room.bookedSlots, hasLength(2));
      expect(room.bookedByBureaus, ['Biro A', 'Biro B']);
      expect(room.facilities, ['tv-led', 'kamera']);
      expect(room.bookedInformation, contains('16:00 - 17:00'));
      expect(room.bookedInformation, contains('Biro B'));
    },
  );

  test('ATK maps nested category and caches the successful request', () async {
    var requestCount = 0;
    final repository = _repository((request) async {
      requestCount += 1;
      return http.Response(
        jsonEncode({
          'data': {
            'availableATK': [
              {
                'id': 353,
                'name': 'Amplop Coklat A3',
                'satuan': 'Buah',
                'kategori_atk_id': 36,
                'kategori_atk': {'id': 36, 'nama_kategori': 'AMPLOP'},
              },
            ],
          },
        }),
        200,
      );
    });

    final first = await repository.getAvailableOfficeSupplies();
    final second = await repository.getAvailableOfficeSupplies();

    expect(requestCount, 1);
    expect(identical(first, second), isTrue);
    expect(first.single.id, '353');
    expect(first.single.unit, 'Buah');
    expect(first.single.categoryId, 36);
    expect(first.single.categoryName, 'AMPLOP');
  });

  test('damage category maps code and all subcategories', () async {
    final repository = _repository(
      (request) async => http.Response(
        jsonEncode({
          'data': {
            'availableKategoriKerusakan': [
              {
                'id': 9,
                'kode_kerusakan': 'KRN-JDV6F',
                'name': 'Furniture',
                'sub_kategori': ['Meja', 'Kursi', 'Credenza'],
              },
            ],
          },
        }),
        200,
      ),
    );

    final categories = await repository.getDamageCategories();

    expect(categories.single.name, 'Furniture');
    expect(categories.single.code, 'KRN-JDV6F');
    expect(categories.single.examples, ['Meja', 'Kursi', 'Credenza']);
  });

  test(
    'empty arrays are valid while malformed payload is controlled',
    () async {
      final emptyRepository = _repository(
        (request) async => http.Response(
          jsonEncode({
            'data': {'availableATK': <Object>[]},
          }),
          200,
        ),
      );
      expect(await emptyRepository.getAvailableOfficeSupplies(), isEmpty);

      final malformedRepository = _repository(
        (request) async => http.Response(jsonEncode({'data': {}}), 200),
      );
      expect(
        malformedRepository.getDamageCategories(),
        throwsA(
          isA<ServiceCatalogFailure>().having(
            (failure) => failure.type,
            'type',
            ServiceCatalogFailureType.invalidResponse,
          ),
        ),
      );
    },
  );

  test('network, server, and unauthorized failures stay user-safe', () async {
    Future<ServiceCatalogFailure> failureFor(
      Future<http.Response> Function(http.Request) handler,
    ) async {
      final repository = _repository(handler);
      try {
        await repository.getDamageCategories();
        fail('Expected a service catalog failure.');
      } on ServiceCatalogFailure catch (failure) {
        return failure;
      }
    }

    final network = await failureFor(
      (request) => throw http.ClientException('offline'),
    );
    final server = await failureFor(
      (request) async => http.Response(jsonEncode({'message': 'trace'}), 500),
    );
    final unauthorized = await failureFor(
      (request) async =>
          http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401),
    );

    expect(network.type, ServiceCatalogFailureType.connection);
    expect(network.message, contains('Tidak dapat terhubung'));
    expect(server.type, ServiceCatalogFailureType.server);
    expect(server.message, isNot(contains('trace')));
    expect(unauthorized.type, ServiceCatalogFailureType.unauthorized);
  });
}
