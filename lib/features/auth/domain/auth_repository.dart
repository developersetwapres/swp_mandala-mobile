import 'app_user.dart';
import 'login_response.dart';

abstract interface class AuthRepository {
  Future<bool> checkServerConnection();

  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  Future<AppUser> getCurrentUser();

  Future<void> logout();

  Future<String?> readStoredToken();

  Future<void> clearSession();
}
