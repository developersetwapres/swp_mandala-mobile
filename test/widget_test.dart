import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swp_mandala_mobile/main.dart';

void main() {
  testWidgets('home page shows the primary overview', (tester) async {
    await tester.pumpWidget(const MandalaApp());

    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Helpdesk Mandala'), findsOneWidget);
    expect(find.text('Layanan'), findsOneWidget);
    expect(find.text('Pemesanan Ruang Rapat'), findsWidgets);
    expect(find.text('Aktivitas terbaru'), findsOneWidget);
    expect(find.text('RRG-2026-001'), findsOneWidget);
  });

  testWidgets('helpdesk action gives immediate feedback', (tester) async {
    await tester.pumpWidget(const MandalaApp());

    await tester.tap(find.byKey(const Key('contact_helpdesk')));
    await tester.pump();

    expect(find.text('Menghubungkan ke Helpdesk Mandala…'), findsOneWidget);
  });

  testWidgets('hero stays usable on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MandalaApp());

    expect(find.text('Ada yang bisa\nkami bantu?'), findsOneWidget);
    expect(find.byKey(const Key('contact_helpdesk')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all three recent activities remain reachable by scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MandalaApp());

    await tester.scrollUntilVisible(
      find.text('SRP-2026-009'),
      450,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('ATK-2026-014'), findsOneWidget);
    expect(find.text('SRP-2026-009'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });
}
