enum ServiceSubmissionFailureType {
  unauthorized,
  validation,
  forbidden,
  notFound,
  connection,
  invalidResponse,
  server,
}

class ServiceSubmissionFailure implements Exception {
  const ServiceSubmissionFailure({
    required this.type,
    required this.message,
    this.fieldErrors = const {},
  });

  final ServiceSubmissionFailureType type;
  final String message;
  final Map<String, List<String>> fieldErrors;

  String? messageFor(Iterable<String> fields) {
    for (final field in fields) {
      for (final entry in fieldErrors.entries) {
        if (entry.key == field || entry.key.startsWith('$field.')) {
          if (entry.value.isNotEmpty) return entry.value.first;
        }
      }
    }
    return null;
  }

  String get primaryMessage {
    for (final messages in fieldErrors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return message;
  }
}
