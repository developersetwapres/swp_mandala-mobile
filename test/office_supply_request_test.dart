import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/office_supply/office_supply_request_page.dart';

import 'test_helpers.dart';

void main() {
  Widget requestApp() {
    return MaterialApp(
      theme: AppTheme.light,
      home: const OfficeSupplyRequestPage(user: testUser),
    );
  }

  Future<void> openSelector(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('add_supply_item')));
    await tester.tap(find.byKey(const Key('add_supply_item')));
    await tester.pumpAndSettle();
  }

  Future<void> addMasterItem(
    WidgetTester tester, {
    required String query,
    required String supplyId,
    required String quantity,
  }) async {
    await openSelector(tester);
    await tester.enterText(find.byKey(const Key('supply_search_field')), query);
    await tester.pump();
    await tester.tap(find.byKey(Key('supply_$supplyId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('supply_quantity_field')),
      quantity,
    );
    await tester.tap(find.byKey(const Key('save_supply_item')));
    await tester.pumpAndSettle();
  }

  testWidgets('ATK service opens the request page from home', (tester) async {
    await tester.pumpWidget(homeTestApp());

    await tester.scrollUntilVisible(
      find.byKey(const Key('service_2')),
      380,
      scrollable: find.byType(Scrollable).at(1),
    );
    await tester.tap(find.byKey(const Key('service_2')));
    await tester.pumpAndSettle();

    expect(find.text('Permintaan Alat Tulis Kantor'), findsOneWidget);
    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Biro Umum'), findsOneWidget);
  });

  testWidgets('selector starts with Lain-Lain and supports search', (
    tester,
  ) async {
    await tester.pumpWidget(requestApp());
    await openSelector(tester);

    expect(find.byKey(const Key('supply_other')), findsOneWidget);
    expect(find.byKey(const Key('supply_pen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('supply_search_field')),
      'Kertas',
    );
    await tester.pump();

    expect(find.text('Kertas A4'), findsOneWidget);
    expect(find.text('Kertas F4'), findsOneWidget);
    expect(find.text('Pulpen'), findsNothing);
  });

  testWidgets('existing ATK uses its unit and duplicate opens quantity edit', (
    tester,
  ) async {
    await tester.pumpWidget(requestApp());

    await addMasterItem(
      tester,
      query: 'Kertas A4',
      supplyId: 'paper_a4',
      quantity: '3',
    );

    expect(find.text('Kertas A4'), findsOneWidget);
    expect(find.text('3 Rim'), findsOneWidget);

    await openSelector(tester);
    await tester.enterText(
      find.byKey(const Key('supply_search_field')),
      'Kertas A4',
    );
    await tester.pump();
    expect(find.text('Sudah ditambahkan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('supply_paper_a4')));
    await tester.pumpAndSettle();
    expect(find.text('Edit item permintaan'), findsOneWidget);
    expect(find.text('Satuan otomatis'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('supply_quantity_field')), '5');
    await tester.tap(find.byKey(const Key('save_supply_item')));
    await tester.pumpAndSettle();

    expect(find.text('Kertas A4'), findsOneWidget);
    expect(find.text('5 Rim'), findsOneWidget);
    expect(find.text('1 item'), findsWidgets);
  });

  testWidgets('Lain-Lain validates its fields and joins the basket', (
    tester,
  ) async {
    await tester.pumpWidget(requestApp());
    await openSelector(tester);

    await tester.tap(find.byKey(const Key('supply_other')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('supply_quantity_field')), '');
    await tester.tap(find.byKey(const Key('save_supply_item')));
    await tester.pump();

    expect(find.text('Nama barang perlu diisi.'), findsOneWidget);
    expect(find.text('Jumlah minimal 1.'), findsOneWidget);
    expect(find.text('Satuan barang perlu diisi.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('custom_supply_name')),
      'Label Printer',
    );
    await tester.enterText(find.byKey(const Key('supply_quantity_field')), '4');
    await tester.enterText(find.byKey(const Key('custom_supply_unit')), 'Roll');
    await tester.tap(find.byKey(const Key('save_supply_item')));
    await tester.pumpAndSettle();

    expect(find.text('Label Printer'), findsOneWidget);
    expect(find.text('4 Roll'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('increase_requested_item_0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('increase_requested_item_0')));
    await tester.pump();
    expect(find.text('5 Roll'), findsOneWidget);

    await addMasterItem(
      tester,
      query: 'Pulpen',
      supplyId: 'pen',
      quantity: '10',
    );
    expect(find.text('Label Printer'), findsOneWidget);
    expect(find.text('Pulpen'), findsOneWidget);
    expect(find.text('2 item'), findsWidgets);
  });

  testWidgets('items can be removed and restored with undo', (tester) async {
    await tester.pumpWidget(requestApp());
    await addMasterItem(
      tester,
      query: 'Pulpen',
      supplyId: 'pen',
      quantity: '10',
    );

    await tester.ensureVisible(
      find.byKey(const Key('remove_requested_item_0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('remove_requested_item_0')));
    await tester.pumpAndSettle();
    expect(find.text('Pulpen'), findsNothing);
    expect(find.text('Belum ada item ATK'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(find.text('Pulpen'), findsOneWidget);
    expect(find.text('10 Pcs'), findsOneWidget);
  });

  testWidgets('submit requires at least one item and a valid phone number', (
    tester,
  ) async {
    await tester.pumpWidget(requestApp());

    ElevatedButton submitButton() => tester.widget<ElevatedButton>(
      find.byKey(const Key('submit_supply_request')),
    );

    expect(submitButton().onPressed, isNull);

    await addMasterItem(
      tester,
      query: 'Binder Clip',
      supplyId: 'binder_clip',
      quantity: '2',
    );
    expect(submitButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('supply_phone_field')),
      '081234567890',
    );
    await tester.pump();
    expect(submitButton().onPressed, isNotNull);

    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit_supply_request')));
    await tester.pumpAndSettle();
    expect(find.text('Permintaan ATK berhasil diajukan.'), findsOneWidget);
  });

  testWidgets('request header and basket fit a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(requestApp());
    await tester.pump();

    expect(find.text('Permintaan Alat Tulis Kantor'), findsOneWidget);
    expect(find.byKey(const Key('add_supply_item')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
