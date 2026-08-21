class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const {},
  });

  final int statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
}

class ApiConnectionException implements Exception {
  const ApiConnectionException();
}
