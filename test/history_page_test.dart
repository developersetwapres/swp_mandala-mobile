import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_failure.dart';
import 'package:swp_mandala_mobile/features/history/presentation/history_page.dart';

import 'test_helpers.dart';

HistoryEntry _entry(int index, String type) => HistoryEntry.fromJson({
  'id': 'entry-$index',
  'type': type,
  'is_read': index.isEven ? 0 : 1,
  'code': 'REQ-${index.toString().padLeft(3, '0')}',
  'title': 'Pengajuan nomor $index',
  'info': 'Informasi layanan nomor $index',
  'created_at': '2026-08-21T08:58:43.000000Z',
  'status': index.isEven ? 'pending' : 'approved',
});

void main() {
  testWidgets('History renders all types with active bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(homeTestApp());
    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();

    expect(find.text('RRT-0821-ABC'), findsOneWidget);
    expect(find.text('ATK-0821-VPV'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('KRS-0820-ZZZ'),
      find.byKey(const Key('history_scroll')),
      const Offset(0, -320),
    );
    expect(find.text('KRS-0820-ZZZ'), findsOneWidget);
    expect(find.text('Tanggal tidak tersedia'), findsOneWidget);
    expect(find.byKey(const Key('primary_bottom_navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service filters and search work together', (tester) async {
    await tester.pumpWidget(homeTestApp());
    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('history_filter_officeSupply')));
    await tester.pump();
    expect(find.text('ATK-0821-VPV'), findsOneWidget);
    expect(find.text('RRT-0821-ABC'), findsNothing);
    expect(find.text('KRS-0820-ZZZ'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('history_search_field')),
      'Amplop',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ATK-0821-VPV'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('history_search_field')),
      'Ruang Rapat',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('history_empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset_history_filters')));
    await tester.pump();
    expect(find.text('RRT-0821-ABC'), findsOneWidget);

    for (final filter in ['meetingRoom', 'officeSupply', 'damage']) {
      await tester.tap(find.byKey(Key('history_filter_$filter')));
      await tester.pump();
      expect(find.byKey(const Key('history_empty')), findsNothing);
    }
  });

  testWidgets('server pagination loads a selected page from the footer', (
    tester,
  ) async {
    final entries = List.generate(
      15,
      (index) => _entry(index, switch (index % 3) {
        0 => 'ATK',
        1 => 'Ruangan Rapat',
        _ => 'Kerusakan',
      }),
    );
    final repository = TestHistoryRepository(entries: entries);
    await tester.pumpWidget(testApp(home: HistoryPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('REQ-000'), findsOneWidget);
    expect(find.text('REQ-012'), findsNothing);

    await tester.dragUntilVisible(
      find.byKey(const Key('history_page_3')),
      find.byKey(const Key('history_scroll')),
      const Offset(0, -320),
    );
    await tester.tap(find.byKey(const Key('history_page_3')));
    await tester.pumpAndSettle();

    expect(find.text('REQ-014'), findsOneWidget);
    expect(find.text('Menampilkan 11–15 dari 15 pengajuan'), findsOneWidget);
    expect(repository.calls, 2);
  });

  testWidgets('empty API and empty search have distinct states', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: HistoryPage(
          key: const ValueKey('empty-history-page'),
          repository: TestHistoryRepository(entries: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada history'), findsOneWidget);

    await tester.pumpWidget(
      testApp(
        home: HistoryPage(
          key: const ValueKey('search-history-page'),
          repository: TestHistoryRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('history_search_field')),
      'kode-yang-tidak-ada',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.dragUntilVisible(
      find.byKey(const Key('history_empty')),
      find.byKey(const Key('history_scroll')),
      const Offset(0, -300),
    );
    expect(find.text('Tidak ada hasil yang sesuai'), findsOneWidget);
  });

  testWidgets('initial loading uses skeleton and backend error is retryable', (
    tester,
  ) async {
    final completer = Completer<List<HistoryEntry>>();
    await tester.pumpWidget(
      testApp(
        home: HistoryPage(
          key: const ValueKey('loading-history-page'),
          repository: TestHistoryRepository(response: completer.future),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('history_skeleton')), findsOneWidget);
    completer.complete(TestHistoryRepository.defaultHistory);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_skeleton')), findsNothing);

    await tester.pumpWidget(
      testApp(
        home: HistoryPage(
          key: const ValueKey('error-history-page'),
          repository: TestHistoryRepository(
            error: const HistoryFailure(
              HistoryFailureType.connection,
              'Tidak dapat terhubung ke server. Silakan coba lagi.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('history_error')),
      find.byKey(const Key('history_scroll')),
      const Offset(0, -300),
    );
    expect(
      find.text('Tidak dapat terhubung ke server. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry_history')), findsOneWidget);
  });

  testWidgets('pull-to-refresh fetches fresh History data', (tester) async {
    final repository = TestHistoryRepository();
    await tester.pumpWidget(testApp(home: HistoryPage(repository: repository)));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);

    await tester.drag(
      find.byKey(const Key('history_scroll')),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('History remains usable on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testApp(home: HistoryPage(repository: TestHistoryRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history_search_field')), findsOneWidget);
    expect(find.byKey(const Key('primary_bottom_navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
