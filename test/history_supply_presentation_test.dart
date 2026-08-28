import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/presentation/history_supply_presentation.dart';

HistorySupplyItem _item({
  required String name,
  required String status,
  int? requested,
  int? approved,
  String? originId,
  String? replacedBy,
}) => HistorySupplyItem.fromJson({
  'name': name,
  'status': status,
  'satuan': 'Pcs',
  'requested': requested,
  'approved': approved,
  'origin_id': originId,
  'replacedBy': replacedBy,
});

void main() {
  test('keeps normal requests as separate logical items', () {
    final items = logicalSupplyRequestItems([
      _item(name: 'Pulpen', status: 'normal', requested: 2),
      _item(name: 'Kertas', status: 'normal', requested: 1),
    ]);

    expect(items, hasLength(2));
    expect(items.map((item) => item.requestedItem.name), ['Pulpen', 'Kertas']);
  });

  test('keeps unmapped custom request as one logical item', () {
    final items = logicalSupplyRequestItems([
      _item(name: 'Pulpen', status: 'normal', requested: 2),
      _item(name: 'Map khusus', status: 'custom', requested: 1),
    ]);

    expect(items, hasLength(2));
    expect(items.last.isCustomRequest, isTrue);
    expect(items.last.replacementItem, isNull);
  });

  test('groups a replaced custom request with its replacement', () {
    final items = logicalSupplyRequestItems([
      _item(name: 'Amplop', status: 'normal', requested: 7, approved: 7),
      _item(
        name: 'Album Foto',
        status: 'replaced',
        requested: 3,
        approved: 0,
        replacedBy: 'Album Foto 10R',
      ),
      _item(
        name: 'Album Foto 10R',
        status: 'replacement',
        requested: 3,
        approved: 3,
        originId: 'Album Foto',
      ),
    ]);

    expect(items, hasLength(2));
    expect(items.last.requestedItem.name, 'Album Foto');
    expect(items.last.replacementItem?.name, 'Album Foto 10R');
    expect(items.last.approvalItem?.approved, 3);
  });

  test('preserves partial fulfillment from the replacement record', () {
    final items = logicalSupplyRequestItems([
      _item(
        name: 'Album Foto',
        status: 'replaced',
        requested: 3,
        approved: 0,
        replacedBy: 'Album Foto 10R',
      ),
      _item(
        name: 'Album Foto 10R',
        status: 'replacement',
        requested: 3,
        approved: 1,
        originId: 'Album Foto',
      ),
    ]);

    expect(items.single.approvalItem?.approved, 1);
  });

  test('keeps malformed or unmatched relationship records visible', () {
    final items = logicalSupplyRequestItems([
      _item(
        name: 'Album Foto',
        status: 'replaced',
        requested: 3,
        replacedBy: 'Album Foto 10R',
      ),
      _item(
        name: 'Album Foto 5R',
        status: 'replacement',
        requested: 3,
        originId: 'Album Foto lain',
      ),
      _item(name: 'Tidak dikenal', status: 'future_status', requested: 1),
    ]);

    expect(items, hasLength(3));
    expect(items.first.isMissingReplacement, isTrue);
    expect(items[1].isUnmatchedReplacement, isTrue);
    expect(items[2].requestedItem.name, 'Tidak dikenal');
  });
}
