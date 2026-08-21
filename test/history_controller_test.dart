import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/presentation/history_controller.dart';

import 'test_helpers.dart';

void main() {
  test('filter and search combine across service-specific fields', () async {
    final controller = HistoryController(
      repository: TestHistoryRepository(),
      pageSize: 2,
      loadMoreDelay: Duration.zero,
    );
    await controller.load();

    expect(controller.visibleEntries, hasLength(2));
    controller.setFilter(HistoryFilter.officeSupply);
    expect(controller.matchingEntries.single.code, 'ATK-0821-VPV');

    controller.setQuery('Amplop');
    expect(controller.matchingEntries.single.typeLabel, 'ATK');
    controller.setQuery('Ruang Rapat Buton');
    expect(controller.matchingEntries, isEmpty);

    controller.setFilter(HistoryFilter.all);
    expect(controller.matchingEntries.single.code, 'RRT-0821-ABC');
    controller.setQuery('ATK-0821-VPV');
    expect(controller.matchingEntries.single.title, '2 item');
    controller.setQuery('KRN-Q9HCF');
    expect(controller.matchingEntries.single.serviceType.name, 'damage');
  });

  test(
    'client-side pagination progressively reveals data without duplicates',
    () async {
      final entries = List.generate(
        7,
        (index) => HistoryEntry.fromJson({
          'id': 'entry-$index',
          'type': 'ATK',
          'code': 'ATK-$index',
          'title': 'Item $index',
          'created_at': '2026-08-21T08:58:43Z',
          'status': 'pending',
        }),
      );
      final controller = HistoryController(
        repository: TestHistoryRepository(entries: entries),
        pageSize: 3,
        loadMoreDelay: Duration.zero,
      );
      await controller.load();

      expect(controller.visibleEntries, hasLength(3));
      expect(controller.hasMore, isTrue);
      await controller.loadMore();
      expect(controller.visibleEntries, hasLength(6));
      await controller.loadMore();
      expect(controller.visibleEntries, hasLength(7));
      expect(controller.hasMore, isFalse);
      expect(
        controller.visibleEntries.map((entry) => entry.code).toSet(),
        hasLength(7),
      );
      await controller.loadMore();
      expect(controller.visibleEntries, hasLength(7));
    },
  );
}
