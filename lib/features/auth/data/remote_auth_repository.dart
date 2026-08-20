import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/login_response.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _apiClient.post(
        '/login',
        body: {'email': email, 'password': password},
      );
      final response = LoginResponse.fromJson(payload);
      await _tokenStorage.writeToken(response.token);
      return response;
    } on ApiConnectionException {
      throw const AuthFailure(
        AuthFailureType.connection,
        'Tidak dapat terhubung ke server. Periksa koneksi dan coba lagi.',
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 422) {
        throw const AuthFailure(
          AuthFailureType.invalidCredentials,
          'Email atau password tidak sesuai.',
        );
      }
      throw const AuthFailure(
        AuthFailureType.server,
        'Login belum dapat diproses. Silakan coba lagi.',
      );
    } on FormatException {
      throw const AuthFailure(
        AuthFailureType.invalidResponse,
        'Respons server belum dapat diproses. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<AppUser> getCurrentUser() async {
    try {
      final payload = await _apiClient.get('/user', authenticated: true);
      final data = payload['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid current user payload.');
      }
      final userJson = data['user'];
      if (userJson is! Map<String, dynamic>) {
        throw const FormatException('Invalid current user data.');
      }
      return AppUser.fromJson(userJson);
    } on ApiConnectionException {
      throw const AuthFailure(
        AuthFailureType.connection,
        'Tidak dapat terhubung ke server. Periksa koneksi dan coba lagi.',
      );
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        throw const AuthFailure(
          AuthFailureType.unauthorized,
          'Sesi telah berakhir. Silakan masuk kembali.',
        );
      }
      throw const AuthFailure(
        AuthFailureType.server,
        'Data pengguna belum dapat dimuat. Silakan coba lagi.',
      );
    } on FormatException {
      throw const AuthFailure(
        AuthFailureType.invalidResponse,
        'Data pengguna dari server belum dapat diproses.',
      );
    }
  }

  @override
  Future<String?> readStoredToken() => _tokenStorage.readToken();

  @override
  Future<void> clearSession() => _tokenStorage.clearToken();
}
// ignore_for_file: prefer_initializing_formals
