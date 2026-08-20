import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/home_page.dart';
import '../../service_catalog/domain/service_catalog_repository.dart';
import 'auth_controller.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.controller,
    required this.serviceCatalogRepository,
    super.key,
  });

  final AuthController controller;
  final ServiceCatalogRepository serviceCatalogRepository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final child = switch (controller.status) {
          AuthStatus.checkingSession => const _SessionSplash(
            key: ValueKey('session-splash'),
          ),
          AuthStatus.unauthenticated => LoginPage(
            key: const ValueKey('login-page'),
            controller: controller,
          ),
          AuthStatus.authenticated => HomePage(
            key: const ValueKey('home-page'),
            user: controller.currentUser!,
            serviceCatalogRepository: serviceCatalogRepository,
          ),
          AuthStatus.sessionCheckFailed => _SessionErrorPage(
            key: const ValueKey('session-error'),
            message: controller.sessionError,
            onRetry: controller.retrySessionCheck,
            onUseAnotherAccount: controller.logout,
          ),
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: child,
        );
      },
    );
  }
}

class _SessionSplash extends StatelessWidget {
  const _SessionSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1FAFF), Color(0xFFC9EDFD)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MandalaMark(size: 76),
              SizedBox(height: 22),
              Text(
                'Mandala',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 22),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionErrorPage extends StatelessWidget {
  const _SessionErrorPage({
    required this.message,
    required this.onRetry,
    required this.onUseAnotherAccount,
    super.key,
  });

  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onUseAnotherAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const _MandalaMark(size: 68),
                  const SizedBox(height: 24),
                  Text(
                    'Belum dapat memeriksa sesi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message ??
                        'Periksa koneksi internet Anda, kemudian coba kembali.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ),
                  TextButton(
                    onPressed: onUseAnotherAccount,
                    child: const Text('Gunakan akun lain'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MandalaMark extends StatelessWidget {
  const _MandalaMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryStrong],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3050AEDA),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.hub_rounded, size: size * 0.48, color: Colors.white),
    );
  }
}
