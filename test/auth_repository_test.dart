import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swp_mandala_mobile/core/network/api_client.dart';
import 'package:swp_mandala_mobile/core/storage/token_storage.dart';
import 'package:swp_mandala_mobile/features/auth/data/remote_auth_repository.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;
}

void main() {
  test(
    'login uses centralized JSON request and persists returned token',
    () async {
      final storage = _MemoryTokenStorage();
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://src.test/api/login');
        expect(request.method, 'POST');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {
          'email': 'it@set.wapresri.go.id',
          'password': 'secret',
        });
        return http.Response(
          jsonEncode({
            'message': 'Login berhasil.',
            'data': {
              'user': {
                'id': 1,
                'email': 'it@set.wapresri.go.id',
                'name': 'IT Setwapres',
                'unit_kerja': 'Biro Tata Usaha dan Sumber Daya Manusia',
              },
              'token': 'returned-token',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = RemoteAuthRepository(
        apiClient: ApiClient(
          baseUrl: 'http://src.test/api/',
          tokenStorage: storage,
          client: client,
        ),
        tokenStorage: storage,
      );

      final response = await repository.login(
        email: 'it@set.wapresri.go.id',
        password: 'secret',
      );

      expect(response.user.name, 'IT Setwapres');
      expect(storage.token, 'returned-token');
    },
  );

  test('current user request attaches the stored bearer token', () async {
    final storage = _MemoryTokenStorage()..token = 'stored-token';
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://src.test/api/user');
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer stored-token');
      return http.Response(
        jsonEncode({
          'data': {
            'user': {
              'id': 1,
              'email': 'it@set.wapresri.go.id',
              'name': 'IT Setwapres',
              'unit_kerja': 'Biro Tata Usaha dan Sumber Daya Manusia',
            },
          },
        }),
        200,
      );
    });
    final repository = RemoteAuthRepository(
      apiClient: ApiClient(
        baseUrl: 'http://src.test/api',
        tokenStorage: storage,
        client: client,
      ),
      tokenStorage: storage,
    );

    final user = await repository.getCurrentUser();

    expect(user.id, 1);
    expect(user.unitKerja, 'Biro Tata Usaha dan Sumber Daya Manusia');
  });
}
