enum AuthFailureType {
  invalidCredentials,
  unauthorized,
  connection,
  invalidResponse,
  server,
}

class AuthFailure implements Exception {
  const AuthFailure(this.type, this.message);

  final AuthFailureType type;
  final String message;
}
