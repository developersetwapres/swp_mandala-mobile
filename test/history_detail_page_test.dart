import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swp_mandala_mobile/features/history/domain/history_entry.dart';
import 'package:swp_mandala_mobile/features/history/presentation/history_detail_page.dart';
import 'package:swp_mandala_mobile/features/history/presentation/history_page.dart';

import 'test_helpers.dart';

HistoryEntry _atkEntry() => HistoryEntry.fromJson({
  'id': 'supplies',
  'type': 'ATK',
  'is_read': 1,
  'code': 'ATK-DETAIL-01',
  'title': '2 item',
  'info': 'Pulpen 4 Pcs, Map khusus 2 Buah',
  'daftarkebutuhan': [
    {
      'id': 12,
      'name': 'Pulpen Biru',
      'satuan': 'Pcs',
      'status': 'normal',
      'requested': 4,
      'approved': 3,
    },
    {
      'id': null,
      'name': 'Map khusus pimpinan',
      'satuan': 'Buah',
      'status': 'custom',
      'requested': 2,
      'approved': 2,
    },
  ],
  'created_at': '2026-08-21T08:58:43',
  'status': 'approved',
  'no_hp': '081234567890',
  'deskripsi': 'Untuk kebutuhan rapat pimpinan.',
  'user': {
    'id': 7,
    'nip': 'tidak-ditampilkan',
    'pegawai': {
      'name': 'Nadia Pratama',
      'biro': {'nama_biro': 'Biro Umum'},
    },
  },
});

HistoryEntry _atkReplacementEntry() => HistoryEntry.fromJson({
  'id': 'supplies-replacement',
  'type': 'ATK',
  'is_read': 1,
  'code': 'ATK-DETAIL-REPLACEMENT',
  'title': '3 item',
  'daftarkebutuhan': [
    {
      'id': 121,
      'name': 'Amplop Coklat A3',
      'satuan': 'Buah',
      'status': 'normal',
      'requested': 7,
      'approved': 7,
    },
    {
      'id': '13G38',
      'name': 'Album Foto',
      'satuan': 'Pcs',
      'status': 'replaced',
      'requested': 3,
      'approved': 0,
      'replacedBy': 'Album Foto 10R',
    },
    {
      'id': 229,
      'name': 'Album Foto 10R',
      'satuan': 'Pcs',
      'status': 'replacement',
      'requested': 3,
      'approved': 1,
      'origin_id': 'Album Foto',
    },
  ],
  'created_at': '2026-08-21T08:58:43',
  'status': 'partial',
});

HistoryEntry _roomEntry({bool includeFeatures = true}) => HistoryEntry.fromJson(
  {
    'id': 'booking',
    'type': 'Ruangan Rapat',
    'is_read': 1,
    'code': 'RRT-DETAIL-02',
    'title': 'Ruang Rapat Buton',
    'ruangans': {
      'id': 2,
      'nama_ruangan': 'Ruang Rapat Buton',
      'lokasi': 'Gedung 2, Lantai 3',
    },
    'info': 'Koordinasi program strategis.',
    'subtitle': '27 Agustus 2026',
    'created_at': '2026-08-20T10:15:00',
    'status': 'booked',
    'time': '09:00 - 11:00',
    'jenis_rapat': 'internal',
    'is_ti_support': includeFeatures,
    'ti_support_detail': includeFeatures ? 'Perlu operator presentasi.' : null,
    'is_hybrid': includeFeatures,
    'hybrid_detail': includeFeatures ? 'Zoom untuk peserta daerah.' : null,
    'no_hp': '081298765432',
    'deskripsi': 'Koordinasi program strategis.',
  },
);

HistoryEntry _damageEntry({bool withPictures = true}) => HistoryEntry.fromJson({
  'id': 'damage',
  'type': 'Kerusakan',
  'is_read': 1,
  'code': 'KRS-DETAIL-03',
  'title': 'AC Ruang Rapat',
  'info': 'Gedung Sekretariat I Lantai 4',
  'deskripsi': 'AC tidak mengeluarkan udara dingin sejak pagi.',
  'picture': withPictures
      ? ['https://invalid.test/ac-1.jpg', 'https://invalid.test/ac-2.jpg']
      : null,
  'kategori': {
    'id': 4,
    'kode_kerusakan': 'KRN-Q9HCF',
    'bagian_kategori': 'Mekanikal',
    'name': 'Tata Udara',
    'sub_kategori': ['AC', 'Kipas Angin'],
  },
  'created_at': '2026-08-19T07:30:00',
  'status': 'completed',
});

void main() {
  testWidgets('ATK detail renders normal and custom request data safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(home: HistoryDetailPage(entry: _atkEntry())),
    );

    expect(find.text('ATK-DETAIL-01'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('21 Agu 2026 · 08:58'), findsWidgets);
    expect(find.text('Pulpen Biru'), findsOneWidget);
    expect(find.text('Diminta 4 Pcs'), findsOneWidget);
    expect(find.text('Disetujui 3 Pcs'), findsOneWidget);
    expect(find.text('Map khusus pimpinan'), findsOneWidget);
    expect(find.text('Lain-lain'), findsOneWidget);
    expect(find.text('Diminta 2 Buah'), findsOneWidget);
    expect(find.text('Untuk kebutuhan rapat pimpinan.'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Biro Umum'), findsOneWidget);
    expect(find.text('tidak-ditampilkan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ATK replacement remains one request with fulfillment history', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(home: HistoryDetailPage(entry: _atkReplacementEntry())),
    );

    expect(find.text('2 item'), findsOneWidget);
    expect(find.text('2 barang diajukan'), findsOneWidget);
    expect(find.text('Album Foto'), findsOneWidget);
    expect(find.text('Lain-lain'), findsOneWidget);
    expect(find.text('Diminta 3 Pcs'), findsOneWidget);
    expect(find.text('Dipenuhi dengan'), findsOneWidget);
    expect(find.text('Album Foto 10R'), findsOneWidget);
    expect(find.text('Disetujui 1 Pcs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('room detail separates usage schedule and conditional features', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(home: HistoryDetailPage(entry: _roomEntry())),
    );

    expect(find.text('Ruang Rapat Buton'), findsWidgets);
    expect(find.text('Gedung 2, Lantai 3'), findsOneWidget);
    expect(find.text('Tanggal penggunaan'), findsOneWidget);
    expect(find.text('27 Agustus 2026'), findsOneWidget);
    expect(find.text('Jam penggunaan'), findsOneWidget);
    expect(find.text('09:00 - 11:00'), findsOneWidget);
    expect(find.text('Internal'), findsOneWidget);
    expect(find.byKey(const Key('detail_it_support')), findsOneWidget);
    expect(find.text('Perlu operator presentasi.'), findsOneWidget);
    expect(find.byKey(const Key('detail_hybrid')), findsOneWidget);
    expect(find.text('Zoom untuk peserta daerah.'), findsOneWidget);
    expect(find.text('Koordinasi program strategis.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nullable room features stay hidden without empty sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: HistoryDetailPage(entry: _roomEntry(includeFeatures: false)),
      ),
    );

    expect(find.byKey(const Key('detail_it_support')), findsNothing);
    expect(find.byKey(const Key('detail_hybrid')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('damage detail renders category and resilient media gallery', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(home: HistoryDetailPage(entry: _damageEntry())),
    );
    expect(
      find.byKey(const Key('detail_attachment_loading_0')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    expect(find.text('KRS-DETAIL-03'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Gedung Sekretariat I Lantai 4'), findsOneWidget);
    expect(
      find.text('AC tidak mengeluarkan udara dingin sejak pagi.'),
      findsOneWidget,
    );
    expect(find.text('Tata Udara'), findsOneWidget);
    expect(find.text('Mekanikal'), findsOneWidget);
    expect(find.text('KRN-Q9HCF'), findsOneWidget);
    expect(find.byKey(const Key('detail_attachment_gallery')), findsOneWidget);
    expect(find.text('2 media dilampirkan'), findsOneWidget);
    expect(find.byKey(const Key('detail_attachment_error_0')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('history_detail_scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail_attachment_0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attachment_viewer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('attachment_viewer_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attachment_viewer')), findsNothing);
  });

  testWidgets('null damage attachment omits gallery without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: HistoryDetailPage(entry: _damageEntry(withPictures: false)),
      ),
    );

    expect(find.byKey(const Key('detail_damage_attachments')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail uses selected object and preserves History state', (
    tester,
  ) async {
    final repository = TestHistoryRepository(
      entries: [_atkEntry(), _roomEntry()],
    );
    await tester.pumpWidget(testApp(home: HistoryPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('history_search_field')),
      'RRT-DETAIL-02',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(
      find.byKey(const Key('history_detail_action_0')),
    );
    await tester.tap(find.byKey(const Key('history_detail_action_0')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('history_detail_code')),
        matching: find.text('RRT-DETAIL-02'),
      ),
      findsOneWidget,
    );
    expect(find.text('ATK-DETAIL-01'), findsNothing);

    await tester.tap(find.byKey(const Key('history_detail_back')));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('history_search_field')),
    );
    expect(searchField.controller?.text, 'RRT-DETAIL-02');
    expect(repository.calls, 1);
    expect(
      find.descendant(
        of: find.byKey(const Key('history_item_0')),
        matching: find.text('RRT-DETAIL-02'),
      ),
      findsOneWidget,
    );
  });
}
