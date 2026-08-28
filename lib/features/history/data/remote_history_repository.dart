// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/history_entry.dart';
import '../domain/history_failure.dart';
import '../domain/history_page_result.dart';
import '../domain/history_repository.dart';

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<HistoryEntry>> getHistory() async =>
      (await getHistoryPage()).entries;

  @override
  Future<HistoryPageResult> getHistoryPage({
    int page = 1,
    String search = '',
  }) async {
    try {
      final queryParameters = <String, String>{'page': page.toString()};
      if (search.trim().isNotEmpty) queryParameters['search'] = search.trim();
      final payload = await _apiClient.get(
        '/history-pengajuan',
        authenticated: true,
        queryParameters: queryParameters,
      );
      final data = payload['data'];
      if (data is! List) {
        throw const FormatException('Invalid history response.');
      }
      final meta = payload['meta'];
      if (meta is! Map) throw const FormatException('Invalid pagination.');
      final parsedMeta = Map<String, dynamic>.from(meta);
      final currentPage = _intValue(parsedMeta['current_page']);
      final lastPage = _intValue(parsedMeta['last_page']);
      final total = _intValue(parsedMeta['total']);
      if (currentPage == null || lastPage == null || total == null) {
        throw const FormatException('Invalid pagination.');
      }
      final links = parsedMeta['links'];
      final pageLinks = links is List
          ? links.whereType<Map>().map((link) {
              final item = Map<String, dynamic>.from(link);
              final label = item['label']?.toString().trim() ?? '';
              return HistoryPageLink(
                // Laravel also includes Previous/Next in meta.links. Those
                // carry a page value, but are rendered by their own buttons.
                page: RegExp(r'^\d+$').hasMatch(label)
                    ? _intValue(item['page']) ?? -1
                    : -1,
                active: item['active'] == true,
              );
            }).where((link) => link.page > 0).toList(growable: false)
          : const <HistoryPageLink>[];
      final responseLinks = payload['links'];
      final parsedResponseLinks = responseLinks is Map
          ? Map<String, dynamic>.from(responseLinks)
          : const <String, dynamic>{};
      return HistoryPageResult(
        entries: List.unmodifiable(data.whereType<Map>().map(
          (item) => HistoryEntry.fromJson(Map<String, dynamic>.from(item)),
        )),
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
        from: _intValue(parsedMeta['from']),
        to: _intValue(parsedMeta['to']),
        pageLinks: pageLinks,
        previousPage: _pageFromUrl(parsedResponseLinks['prev']),
        nextPage: _pageFromUrl(parsedResponseLinks['next']),
      );
    } catch (error) {
      if (error is HistoryFailure) rethrow;
      if (error is ApiConnectionException) {
        throw const HistoryFailure(
          HistoryFailureType.connection,
          'Tidak dapat terhubung ke server. Silakan coba lagi.',
        );
      }
      if (error is ApiException) {
        throw HistoryFailure(
          error.isUnauthorized
              ? HistoryFailureType.unauthorized
              : HistoryFailureType.server,
          error.message,
        );
      }
      if (error is FormatException) {
        throw const HistoryFailure(
          HistoryFailureType.invalidResponse,
          'Data history dari server belum dapat diproses.',
        );
      }
      throw const HistoryFailure(
        HistoryFailureType.server,
        'History belum dapat dimuat. Silakan coba lagi.',
      );
    }
  }
}

int? _intValue(Object? value) => switch (value) {
  int value => value,
  num value => value.toInt(),
  String value => int.tryParse(value),
  _ => null,
};

int? _pageFromUrl(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return int.tryParse(Uri.tryParse(value)?.queryParameters['page'] ?? '');
}
