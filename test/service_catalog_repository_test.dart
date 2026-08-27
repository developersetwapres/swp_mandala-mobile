import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swp_mandala_mobile/core/network/api_client.dart';
import 'package:swp_mandala_mobile/core/storage/token_storage.dart';
import 'package:swp_mandala_mobile/features/service_catalog/data/remote_service_catalog_repository.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_catalog_failure.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_submission_failure.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_submission_models.dart';
import 'package:swp_mandala_mobile/features/damage_report/damage_report_models.dart';

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
            'data': [
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
          'data': [
            {
              'id': 353,
              'name': 'Amplop Coklat A3',
              'satuan': 'Buah',
              'kategori_atk_id': 36,
              'kategori_atk': {'id': 36, 'nama_kategori': 'AMPLOP'},
            },
          ],
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
          'data': [
            {
              'id': 9,
              'kode_kerusakan': 'KRN-JDV6F',
              'name': 'Furniture',
              'sub_kategori': ['Meja', 'Kursi', 'Credenza'],
            },
          ],
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
        (request) async => http.Response(jsonEncode({'data': <Object>[]}), 200),
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

  test('previous keyed data wrapper remains supported', () async {
    final repository = _repository(
      (request) async => http.Response(
        jsonEncode({
          'data': {
            'availableKategoriKerusakan': [
              {
                'id': 4,
                'kode_kerusakan': 'KRN-SZ8F4',
                'name': 'Kelistrikan',
                'sub_kategori': ['Stop Kontak', 'Lampu Penerangan'],
              },
            ],
          },
        }),
        200,
      ),
    );

    final categories = await repository.getDamageCategories();

    expect(categories.single.code, 'KRN-SZ8F4');
  });

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

  test('room submit sends the exact Laravel JSON contract', () async {
    final repository = _repository((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/permintaan-ruang-rapat');
      expect(request.headers['Authorization'], 'Bearer stored-token');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'room_code': 'RPT-2V4N9',
        'room_name': 'Ruang Rapat Utama',
        'date': '2026-08-20',
        'startTime': '08:00',
        'endTime': '10:00',
        'purpose': 'Rapat koordinasi program kerja',
        'jumlahPeserta': '20',
        'contact': '081234567890',
        'jenisRapat': 'internal',
        'needItSupport': false,
        'itSupportDetail': null,
        'isHybrid': true,
        'hybridDetail': 'Menggunakan Zoom',
      });
      return http.Response(
        jsonEncode({
          'message': 'Pesan sukses ruang dari backend.',
          'data': <String, Object?>{},
        }),
        201,
      );
    });

    final response = await repository.submitRoomBooking(
      const RoomBookingSubmission(
        roomCode: 'RPT-2V4N9',
        roomName: 'Ruang Rapat Utama',
        date: '2026-08-20',
        startTime: '08:00',
        endTime: '10:00',
        purpose: 'Rapat koordinasi program kerja',
        participantCount: '20',
        contact: '081234567890',
        meetingType: 'internal',
        needItSupport: false,
        itSupportDetail: null,
        isHybrid: true,
        hybridDetail: 'Menggunakan Zoom',
      ),
    );

    expect(response.message, 'Pesan sukses ruang dari backend.');
  });

  test('ATK submit preserves real IDs and nullable custom item ID', () async {
    final repository = _repository((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/permintaan-atk');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['justification'], 'Kebutuhan operasional unit kerja');
      expect(payload['contact'], '081234567890');
      expect(payload['items'], [
        {
          'id': 353,
          'name': 'Amplop Coklat A3',
          'satuan': 'Buah',
          'status': 'normal',
          'requested': 3,
          'approved': 0,
        },
        {
          'id': null,
          'name': 'Label Printer',
          'satuan': 'Roll',
          'status': 'custom',
          'requested': 5,
          'approved': 0,
        },
      ]);
      return http.Response(
        jsonEncode({'message': 'Pesan sukses ATK dari backend.'}),
        201,
      );
    });

    final response = await repository.submitOfficeSupplyRequest(
      const OfficeSupplySubmission(
        items: [
          OfficeSupplySubmissionItem(
            id: 353,
            name: 'Amplop Coklat A3',
            unit: 'Buah',
            requested: 3,
            isCustom: false,
          ),
          OfficeSupplySubmissionItem(
            id: null,
            name: 'Label Printer',
            unit: 'Roll',
            requested: 5,
            isCustom: true,
          ),
        ],
        justification: 'Kebutuhan operasional unit kerja',
        contact: '081234567890',
      ),
    );

    expect(response.message, 'Pesan sukses ATK dari backend.');
  });

  test('damage submit uses authenticated multipart photos array', () async {
    final repository = _repository((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/laporan-kerusakan-sarpras');
      expect(request.headers['Authorization'], 'Bearer stored-token');
      expect(request.headers['Accept'], 'application/json');
      expect(
        request.headers['Content-Type'],
        startsWith('multipart/form-data;'),
      );
      final body = latin1.decode(request.bodyBytes);
      expect(body, contains('name="location"'));
      expect(body, contains('Gedung Sekretariat I Lantai 4'));
      expect(body, contains('name="damageType"'));
      expect(body, contains('AC Ruang Rapat'));
      expect(body, contains('name="kategori"'));
      expect(body, contains('KRN-Q9HCF'));
      expect(body, contains('name="description"'));
      expect(body, contains('AC tidak dingin.'));
      expect(body, contains('name="contact"'));
      expect(body, contains('081234567890'));
      expect(body, contains('name="photos[]"'));
      expect(body, contains('filename="bukti.jpg"'));
      return http.Response(
        jsonEncode({'message': 'Pesan sukses laporan dari backend.'}),
        201,
      );
    });

    final response = await repository.submitDamageReport(
      DamageReportSubmission(
        location: 'Gedung Sekretariat I Lantai 4',
        damageType: 'AC Ruang Rapat',
        categoryCode: 'KRN-Q9HCF',
        description: 'AC tidak dingin.',
        contact: '081234567890',
        attachments: [
          DamageAttachment(
            id: 'attachment-1',
            name: 'bukti.jpg',
            sizeBytes: 3,
            kind: DamageAttachmentKind.image,
            previewBytes: Uint8List.fromList([1, 2, 3]),
          ),
        ],
      ),
    );

    expect(response.message, 'Pesan sukses laporan dari backend.');
  });

  test(
    'Laravel validation message and field errors are not swallowed',
    () async {
      final repository = _repository(
        (request) async => http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'contact': ['The contact field is required.'],
              'photos.0': ['Ukuran foto maksimal 5 MB.'],
            },
          }),
          422,
        ),
      );

      try {
        await repository.submitDamageReport(
          DamageReportSubmission(
            location: 'Gedung I',
            damageType: 'AC',
            categoryCode: 'KRN-AIR',
            description: 'Rusak',
            contact: '',
            attachments: [
              DamageAttachment(
                id: 'attachment-1',
                name: 'besar.jpg',
                sizeBytes: 6 * 1024 * 1024,
                kind: DamageAttachmentKind.image,
                previewBytes: Uint8List(1),
              ),
            ],
          ),
        );
        fail('Expected validation failure.');
      } on ServiceSubmissionFailure catch (failure) {
        expect(failure.type, ServiceSubmissionFailureType.validation);
        expect(failure.message, 'The given data was invalid.');
        expect(
          failure.messageFor(['contact']),
          'The contact field is required.',
        );
        expect(failure.messageFor(['photos']), 'Ukuran foto maksimal 5 MB.');
        expect(failure.primaryMessage, 'The contact field is required.');
      }
    },
  );

  test('business and server JSON messages remain user-facing', () async {
    Future<ServiceSubmissionFailure> failureFor(
      int status,
      String message,
    ) async {
      final repository = _repository(
        (request) async =>
            http.Response(jsonEncode({'message': message}), status),
      );
      try {
        await repository.submitOfficeSupplyRequest(
          const OfficeSupplySubmission(
            items: [],
            justification: 'Kebutuhan unit',
            contact: '081234567890',
          ),
        );
        fail('Expected submission failure.');
      } on ServiceSubmissionFailure catch (failure) {
        return failure;
      }
    }

    final business = await failureFor(403, 'Pengajuan tidak diizinkan.');
    final server = await failureFor(500, 'Terjadi kesalahan khusus backend.');

    expect(business.message, 'Pengajuan tidak diizinkan.');
    expect(
      server.message,
      'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
    );
  });

  test(
    'submit connection fallback is friendly only without a response',
    () async {
      final repository = _repository(
        (request) => throw http.ClientException('socket detail'),
      );

      expect(
        repository.submitRoomBooking(
          const RoomBookingSubmission(
            roomCode: 'RPT-2V4N9',
            date: '2026-08-20',
            startTime: '08:00',
            endTime: '10:00',
            purpose: 'Rapat',
            participantCount: '2',
            contact: '081234567890',
            meetingType: 'internal',
            needItSupport: false,
            itSupportDetail: null,
            isHybrid: false,
            hybridDetail: null,
          ),
        ),
        throwsA(
          isA<ServiceSubmissionFailure>()
              .having(
                (failure) => failure.type,
                'type',
                ServiceSubmissionFailureType.connection,
              )
              .having(
                (failure) => failure.message,
                'message',
                'Tidak dapat terhubung ke server. Silakan coba lagi.',
              ),
        ),
      );
    },
  );
}
