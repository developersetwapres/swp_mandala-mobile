import 'package:flutter/foundation.dart';

import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';

enum AuthStatus {
  checkingSession,
  unauthenticated,
  authenticated,
  sessionCheckFailed,
}

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.checkingSession;
  AppUser? _currentUser;
  String? _loginError;
  String? _sessionError;
  bool _isLoggingIn = false;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get loginError => _loginError;
  String? get sessionError => _sessionError;
  bool get isLoggingIn => _isLoggingIn;

  Future<void> initialize() async {
    _status = AuthStatus.checkingSession;
    _currentUser = null;
    _sessionError = null;
    notifyListeners();

    try {
      final token = await _repository.readStoredToken();
      if (token == null || token.trim().isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _currentUser = await _repository.getCurrentUser();
      _loginError = null;
      _status = AuthStatus.authenticated;
    } on AuthFailure catch (failure) {
      if (failure.type == AuthFailureType.unauthorized) {
        await _clearSessionQuietly();
        _loginError = failure.message;
        _status = AuthStatus.unauthenticated;
      } else {
        _sessionError = failure.message;
        _status = AuthStatus.sessionCheckFailed;
      }
    } catch (_) {
      _sessionError =
          'Sesi belum dapat diperiksa. Periksa koneksi lalu coba lagi.';
      _status = AuthStatus.sessionCheckFailed;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (_isLoggingIn) return false;

    _isLoggingIn = true;
    _loginError = null;
    notifyListeners();

    try {
      await _repository.login(email: email.trim(), password: password);
      _currentUser = await _repository.getCurrentUser();
      _status = AuthStatus.authenticated;
      return true;
    } on AuthFailure catch (failure) {
      if (failure.type == AuthFailureType.unauthorized) {
        await _clearSessionQuietly();
      }
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _loginError = failure.message;
      return false;
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _loginError = 'Login belum dapat diproses. Silakan coba lagi.';
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> retrySessionCheck() => initialize();

  Future<void> logout() async {
    await _clearSessionQuietly();
    _currentUser = null;
    _loginError = null;
    _sessionError = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _clearSessionQuietly() async {
    try {
      await _repository.clearSession();
    } catch (_) {
      // Local cleanup failure must never expose storage details to the UI.
    }
  }
}
