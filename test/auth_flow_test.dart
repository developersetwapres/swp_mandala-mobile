import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/auth/domain/app_user.dart';
import 'package:swp_mandala_mobile/features/auth/domain/auth_failure.dart';
import 'package:swp_mandala_mobile/features/auth/domain/auth_repository.dart';
import 'package:swp_mandala_mobile/features/auth/domain/login_response.dart';
import 'package:swp_mandala_mobile/features/auth/presentation/auth_controller.dart';
import 'package:swp_mandala_mobile/main.dart';

const _apiUser = AppUser(
  id: 1,
  email: 'it@set.wapresri.go.id',
  name: 'IT Setwapres',
  unitKerja: 'Biro Tata Usaha dan Sumber Daya Manusia',
);

class _FakeAuthRepository implements AuthRepository {
  String? storedToken;
  AuthFailure? loginFailure;
  AuthFailure? currentUserFailure;
  int loginCalls = 0;
  int currentUserCalls = 0;
  int clearCalls = 0;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    loginCalls += 1;
    if (loginFailure case final failure?) throw failure;
    storedToken = 'secure-test-token';
    return const LoginResponse(
      message: 'Login berhasil.',
      user: _apiUser,
      token: 'secure-test-token',
    );
  }

  @override
  Future<AppUser> getCurrentUser() async {
    currentUserCalls += 1;
    if (currentUserFailure case final failure?) throw failure;
    return _apiUser;
  }

  @override
  Future<String?> readStoredToken() async => storedToken;

  @override
  Future<void> clearSession() async {
    clearCalls += 1;
    storedToken = null;
  }
}

Future<AuthController> _pumpAuthApp(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  final controller = AuthController(repository);
  await tester.pumpWidget(MandalaApp(authController: controller));
  await controller.initialize();
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _fillValidCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    'it@set.wapresri.go.id',
  );
  await tester.enterText(
    find.byKey(const Key('login-password')),
    'valid-password',
  );
}

void main() {
  testWidgets('valid login stores session, loads user, and opens home', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final controller = await _pumpAuthApp(tester, repository);

    await _fillValidCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(repository.currentUserCalls, 1);
    expect(repository.storedToken, 'secure-test-token');
    expect(controller.currentUser, _apiUser);
    expect(find.text('IT Setwapres'), findsOneWidget);
    expect(find.text('Layanan'), findsOneWidget);
  });

  testWidgets('wrong password stays on login with friendly feedback', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginFailure = const AuthFailure(
        AuthFailureType.invalidCredentials,
        'Email atau password tidak sesuai.',
      );
    final controller = await _pumpAuthApp(tester, repository);

    await _fillValidCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau password tidak sesuai.'), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(controller.isLoggingIn, isFalse);
    expect(controller.status, AuthStatus.unauthenticated);
  });

  testWidgets('network failure is controlled and keeps the login available', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginFailure = const AuthFailure(
        AuthFailureType.connection,
        'Tidak dapat terhubung ke server. Periksa koneksi dan coba lagi.',
      );
    await _pumpAuthApp(tester, repository);

    await _fillValidCredentials(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tidak dapat terhubung ke server. Periksa koneksi dan coba lagi.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('app restart validates a stored token before opening home', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()..storedToken = 'stored-token';
    final controller = await _pumpAuthApp(tester, repository);

    expect(repository.loginCalls, 0);
    expect(repository.currentUserCalls, 1);
    expect(controller.status, AuthStatus.authenticated);
    expect(find.text('IT Setwapres'), findsOneWidget);
  });

  testWidgets('invalid stored token is cleared and returns to login', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..storedToken = 'expired-token'
      ..currentUserFailure = const AuthFailure(
        AuthFailureType.unauthorized,
        'Sesi telah berakhir. Silakan masuk kembali.',
      );
    final controller = await _pumpAuthApp(tester, repository);

    expect(repository.clearCalls, 1);
    expect(repository.storedToken, isNull);
    expect(controller.currentUser, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(
      find.text('Sesi telah berakhir. Silakan masuk kembali.'),
      findsOneWidget,
    );
  });

  testWidgets('login validates email and password before sending a request', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await _pumpAuthApp(tester, repository);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
    expect(repository.loginCalls, 0);

    await tester.enterText(find.byKey(const Key('login-email')), 'email-salah');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Masukkan format email yang valid.'), findsOneWidget);
  });
}
