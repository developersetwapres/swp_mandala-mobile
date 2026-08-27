import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('home page shows the primary overview', (tester) async {
    await tester.pumpWidget(homeTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Helpdesk Mandala'), findsOneWidget);
    expect(find.text('Layanan'), findsOneWidget);
    expect(find.text('Pemesanan Ruang Rapat'), findsWidgets);
    expect(find.text('Aktivitas terbaru'), findsOneWidget);
    expect(find.text('RRT-0821-ABC'), findsOneWidget);
  });

  testWidgets('helpdesk action gives immediate feedback', (tester) async {
    await tester.pumpWidget(homeTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contact_helpdesk')));
    await tester.pump();

    expect(find.text('Menghubungkan ke Helpdesk Mandala…'), findsOneWidget);
  });

  testWidgets('primary shell opens History and returns to Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(homeTestApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('primary_bottom_navigation')), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    expect(
      find.text('Pantau perjalanan seluruh pengajuan layananmu.'),
      findsOneWidget,
    );
    expect(find.text('ATK-0821-VPV'), findsOneWidget);
    expect(find.text('Layanan'), findsNothing);

    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle();
    expect(find.text('Layanan'), findsOneWidget);
  });

  testWidgets('hero stays usable on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(homeTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Ada yang bisa\nkami bantu?'), findsOneWidget);
    expect(find.byKey(const Key('contact_helpdesk')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all three recent activities remain reachable by scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(homeTestApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('KRS-0820-ZZZ'),
      450,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('ATK-0821-VPV'), findsOneWidget);
    expect(find.text('KRS-0820-ZZZ'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('home limits API history to the three most recent activities', (
    tester,
  ) async {
    final newest = HistoryEntry.fromJson({
      'id': 'newest',
      'type': 'Kerusakan',
      'code': 'KRS-NEWEST',
      'title': 'Aktivitas paling baru',
      'created_at': '2026-08-27T09:00:00.000000Z',
      'status': 'pending',
    });
    final repository = TestHistoryRepository(
      entries: [newest, ...TestHistoryRepository.defaultHistory],
    );

    await tester.pumpWidget(homeTestApp(historyRepository: repository));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(find.text('KRS-NEWEST'), findsOneWidget);
    expect(find.text('RRT-0821-ABC'), findsOneWidget);
    expect(find.text('ATK-0821-VPV'), findsOneWidget);
    expect(find.text('KRS-0820-ZZZ'), findsNothing);
  });
}
