import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_upload_file.dart';

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
    Map<String, String>? queryParameters,
  }) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(
      () => _client.get(
        _uri(path, queryParameters: queryParameters),
        headers: headers,
      ),
    );
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

  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required Map<String, String> fields,
    required List<ApiUploadFile> files,
    bool authenticated = false,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      request.headers.addAll(
        await _headers(authenticated: authenticated, includeContentType: false),
      );
      request.fields.addAll(fields);
      for (final file in files) {
        request.files.add(await file.toMultipartFile());
      }
      final streamedResponse = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiConnectionException();
    } on http.ClientException {
      throw const ApiConnectionException();
    }
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    final uri = Uri.parse('$_baseUrl/$normalizedPath');
    return queryParameters == null || queryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers({
    required bool authenticated,
    bool includeContentType = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (includeContentType) headers['Content-Type'] = 'application/json';

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
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiConnectionException();
    } on http.ClientException {
      throw const ApiConnectionException();
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final payload = _decode(response.body, statusCode: response.statusCode);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _messageFrom(payload),
        fieldErrors: _fieldErrorsFrom(payload),
      );
    }
    return payload;
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

  Map<String, List<String>> _fieldErrorsFrom(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is! Map) return const {};
    final parsed = <String, List<String>>{};
    for (final entry in errors.entries) {
      if (entry.key is! String) continue;
      final value = entry.value;
      final messages = value is List
          ? value.whereType<String>().where((item) => item.isNotEmpty).toList()
          : value is String && value.isNotEmpty
          ? [value]
          : const <String>[];
      if (messages.isNotEmpty) parsed[entry.key as String] = messages;
    }
    return Map.unmodifiable(parsed);
  }
}
// ignore_for_file: prefer_initializing_formals
