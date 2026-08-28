import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/presentation/history_controller.dart';

import 'test_helpers.dart';

void main() {
  test('search is requested from the repository and starts at page one', () async {
    final repository = TestHistoryRepository();
    final controller = HistoryController(repository: repository);

    await controller.load();
    await controller.setQuery('Amplop');

    expect(repository.calls, 2);
    expect(controller.currentPage, 1);
    expect(controller.visibleEntries.single.typeLabel, 'ATK');
  });

  test('page navigation loads the next server page without duplicate entries',
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
    );
    await controller.load();

    expect(controller.visibleEntries, hasLength(5));
    expect(controller.hasNextPage, isTrue);
    await controller.nextPage();
    expect(controller.currentPage, 2);
    expect(controller.visibleEntries, hasLength(2));
    expect(controller.hasNextPage, isFalse);
  });
}
