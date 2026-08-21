enum HistoryFailureType { unauthorized, connection, invalidResponse, server }

class HistoryFailure implements Exception {
  const HistoryFailure(this.type, this.message);

  final HistoryFailureType type;
  final String message;
}
