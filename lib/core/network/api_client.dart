import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final String _baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(() => _client.get(_uri(path), headers: headers));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(
      () => _client.post(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  Uri _uri(String path) {
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$_baseUrl/$normalizedPath');
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Sesi tidak tersedia.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeout);
      final payload = _decode(response.body, statusCode: response.statusCode);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: _messageFrom(payload),
        );
      }
      return payload;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiConnectionException();
    } on http.ClientException {
      throw const ApiConnectionException();
    }
  }

  Map<String, dynamic> _decode(String body, {required int statusCode}) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      // Converted below into a controlled API error.
    }
    throw ApiException(
      statusCode: statusCode,
      message: 'Respons server belum dapat diproses.',
    );
  }

  String _messageFrom(Map<String, dynamic> payload) {
    final message = payload['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : 'Permintaan belum dapat diproses.';
  }
}
// ignore_for_file: prefer_initializing_formals
