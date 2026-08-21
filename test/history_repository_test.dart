import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swp_mandala_mobile/core/network/api_client.dart';
import 'package:swp_mandala_mobile/core/storage/token_storage.dart';
import 'package:swp_mandala_mobile/features/history/data/remote_history_repository.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_failure.dart';

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'history-token';

  @override
  Future<void> writeToken(String token) async {}
}

RemoteHistoryRepository _repository(
  Future<http.Response> Function(http.Request) handler,
) => RemoteHistoryRepository(
  apiClient: ApiClient(
    baseUrl: 'http://src.test/api',
    tokenStorage: _MemoryTokenStorage(),
    client: MockClient(handler),
  ),
);

void main() {
  test(
    'history API parses all service types and nullable nested data',
    () async {
      final repository = _repository((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/history-pengajuan');
        expect(request.headers['Authorization'], 'Bearer history-token');
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'supplies',
                'type': 'ATK',
                'is_read': 0,
                'code': 'ATK-0821-VPV',
                'title': '2 item',
                'ruangans': null,
                'info': 'Amplop Coklat 5 Buah',
                'daftarkebutuhan': [
                  {
                    'id': 353,
                    'name': 'Amplop Coklat',
                    'satuan': 'Buah',
                    'status': 'normal',
                    'approved': 0,
                    'requested': 5,
                  },
                  'malformed optional item',
                ],
                'subtitle': null,
                'created_at': '2026-08-21T08:58:43.000000Z',
                'status': 'pending',
                'user': null,
              },
              {
                'id': 'booking',
                'type': 'Ruangan Rapat',
                'is_read': true,
                'code': 'RRT-0821-ABC',
                'title': 'Ruang Rapat Buton',
                'ruangans': {
                  'id': 2,
                  'nama_ruangan': 'Ruang Rapat Buton',
                  'lokasi': 'Gedung 2, Lantai 3',
                },
                'created_at': '2026-08-20T04:30:00Z',
                'status': 'booked',
                'time': '09:00 - 11:00',
                'user': {
                  'id': 7,
                  'nip': '19800001',
                  'pegawai': {
                    'name': 'Nadia Pratama',
                    'biro': {'nama_biro': 'Biro Umum'},
                  },
                },
              },
              {
                'id': 'damage',
                'type': 'Kerusakan',
                'is_read': '1',
                'code': 'KRS-0820-ZZZ',
                'title': 'AC Ruang Rapat',
                'created_at': 'invalid optional date',
                'status': 'completed',
                'kategori': {
                  'id': 4,
                  'kode_unit': null,
                  'kode_kerusakan': 'KRN-Q9HCF',
                  'bagian_kategori': null,
                  'name': 'Tata Udara',
                  'sub_kategori': ['AC', 'Kipas'],
                },
                'picture': ['https://src.test/storage/ac.jpg', 123],
              },
            ],
          }),
          200,
        );
      });

      final entries = await repository.getHistory();

      expect(entries, hasLength(3));
      expect(entries[0].serviceType, HistoryServiceType.officeSupply);
      expect(entries[0].isRead, isFalse);
      expect(entries[0].supplyItems.single.requested, 5);
      expect(entries[1].serviceType, HistoryServiceType.meetingRoom);
      expect(entries[1].room?.name, 'Ruang Rapat Buton');
      expect(entries[1].user?.employee?.bureauName, 'Biro Umum');
      expect(entries[2].serviceType, HistoryServiceType.damage);
      expect(entries[2].category?.damageCode, 'KRN-Q9HCF');
      expect(entries[2].pictures, ['https://src.test/storage/ac.jpg']);
      expect(entries[2].createdAt, isNull);
    },
  );

  test('empty history response is valid', () async {
    final repository = _repository(
      (request) async => http.Response(jsonEncode({'data': []}), 200),
    );
    expect(await repository.getHistory(), isEmpty);
  });

  test(
    'backend, auth, network, and malformed responses stay controlled',
    () async {
      Future<HistoryFailure> failureFor(
        Future<http.Response> Function(http.Request) handler,
      ) async {
        try {
          await _repository(handler).getHistory();
          fail('Expected HistoryFailure.');
        } on HistoryFailure catch (failure) {
          return failure;
        }
      }

      final server = await failureFor(
        (request) async => http.Response(
          jsonEncode({'message': 'Pesan history dari backend.'}),
          500,
        ),
      );
      final unauthorized = await failureFor(
        (request) async =>
            http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401),
      );
      final network = await failureFor(
        (request) => throw http.ClientException('socket detail'),
      );
      final malformed = await failureFor(
        (request) async => http.Response(jsonEncode({'data': {}}), 200),
      );

      expect(server.message, 'Pesan history dari backend.');
      expect(unauthorized.type, HistoryFailureType.unauthorized);
      expect(network.type, HistoryFailureType.connection);
      expect(network.message, isNot(contains('socket')));
      expect(malformed.type, HistoryFailureType.invalidResponse);
    },
  );
}
