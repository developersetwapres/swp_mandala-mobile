import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/auth/domain/app_user.dart';
import 'package:swp_mandala_mobile/features/home/home_page.dart';

const testUser = AppUser(
  id: 7,
  email: 'nadia.pratama@example.go.id',
  name: 'Nadia Pratama',
  unitKerja: 'Biro Umum',
);

Widget testApp({required Widget home}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  );
}

Widget homeTestApp() => testApp(home: const HomePage(user: testUser));
