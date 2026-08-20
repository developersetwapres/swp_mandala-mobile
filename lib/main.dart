import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/remote_auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/auth_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStorage: tokenStorage,
  );
  final authRepository = RemoteAuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final authController = AuthController(authRepository);

  runApp(MandalaApp(authController: authController));
  authController.initialize();
}

class MandalaApp extends StatelessWidget {
  const MandalaApp({required this.authController, super.key});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: authController,
      child: MaterialApp(
        title: 'Mandala',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AuthGate(controller: authController),
      ),
    );
  }
}
