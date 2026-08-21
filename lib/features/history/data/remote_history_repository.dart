// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/history_entry.dart';
import '../domain/history_failure.dart';
import '../domain/history_repository.dart';

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<HistoryEntry>> getHistory() async {
    try {
      final payload = await _apiClient.get(
        '/history-pengajuan',
        authenticated: true,
      );
      final data = payload['data'];
      if (data is! List) {
        throw const FormatException('Invalid history response.');
      }
      return List.unmodifiable(
        data.whereType<Map>().map(
          (item) => HistoryEntry.fromJson(Map<String, dynamic>.from(item)),
        ),
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
