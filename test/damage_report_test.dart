import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/damage_report/damage_report_models.dart';
import 'package:swp_mandala_mobile/features/damage_report/damage_report_page.dart';

import 'test_helpers.dart';

class _FakeMediaPicker implements DamageMediaPicker {
  _FakeMediaPicker([List<List<DamageAttachmentCandidate>>? responses])
    : responses = responses ?? [];

  final List<List<DamageAttachmentCandidate>> responses;
  int pickCount = 0;

  @override
  Future<List<DamageAttachmentCandidate>> pick(
    DamageMediaSource source, {
    required int limit,
  }) async {
    pickCount += 1;
    if (responses.isEmpty) return const [];
    return responses.removeAt(0).take(limit).toList();
  }

  @override
  Future<List<DamageAttachmentCandidate>> recoverLostMedia() async => const [];
}

void main() {
  Widget reportApp(_FakeMediaPicker picker) {
    return MaterialApp(
      theme: AppTheme.light,
      home: DamageReportPage(user: testUser, mediaPicker: picker),
    );
  }

  testWidgets('damage service opens the report page from home', (tester) async {
    await tester.pumpWidget(homeTestApp());

    await tester.scrollUntilVisible(
      find.byKey(const Key('service_1')),
      190,
      scrollable: find.byType(Scrollable).at(1),
    );
    await tester.tap(find.byKey(const Key('service_1')));
    await tester.pumpAndSettle();

    expect(find.text('Laporan Kerusakan Gedung'), findsOneWidget);
    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Biro Umum'), findsOneWidget);
  });

  testWidgets('category sheet explains options before selection', (
    tester,
  ) async {
    await tester.pumpWidget(reportApp(_FakeMediaPicker()));

    await tester.ensureVisible(find.byKey(const Key('category_picker')));
    await tester.tap(find.byKey(const Key('category_picker')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih kategori kerusakan'), findsOneWidget);
    expect(
      find.text('Termasuk: Mic Conference, Public Address'),
      findsOneWidget,
    );
    expect(find.text('Termasuk: AC, Exhaust Fan, Kipas Angin'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category_tata_udara')));
    await tester.pumpAndSettle();

    expect(find.text('Tata Udara'), findsOneWidget);
    expect(find.text('AC, Exhaust Fan, Kipas Angin'), findsOneWidget);
  });

  testWidgets('valid image and video show previews and can be removed', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([
      const [
        DamageAttachmentCandidate(
          name: 'ac-rusak.jpg',
          sizeBytes: 3 * 1024 * 1024,
          kind: DamageAttachmentKind.image,
        ),
        DamageAttachmentCandidate(
          name: 'suara-ac.mp4',
          sizeBytes: 18 * 1024 * 1024,
          kind: DamageAttachmentKind.video,
        ),
      ],
    ]);
    await tester.pumpWidget(reportApp(picker));

    await tester.ensureVisible(find.byKey(const Key('add_attachment')));
    await tester.tap(find.byKey(const Key('add_attachment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('source_gallery')));
    await tester.pumpAndSettle();

    expect(find.text('ac-rusak.jpg'), findsOneWidget);
    expect(find.text('suara-ac.mp4'), findsOneWidget);
    expect(find.text('2/2 file'), findsOneWidget);
    expect(find.text('Batas lampiran tercapai'), findsOneWidget);
    expect(picker.pickCount, 1);

    await tester.tap(find.byKey(const Key('remove_attachment_0')));
    await tester.pump();

    expect(find.text('ac-rusak.jpg'), findsNothing);
    expect(find.text('1/2 file'), findsOneWidget);
    expect(find.text('Tambahkan foto atau video'), findsOneWidget);
  });

  testWidgets('oversized and unsupported media get friendly feedback', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([
      const [
        DamageAttachmentCandidate(
          name: 'video-besar.mp4',
          sizeBytes: 21 * 1024 * 1024,
          kind: DamageAttachmentKind.video,
        ),
      ],
      const [
        DamageAttachmentCandidate(
          name: 'laporan.pdf',
          sizeBytes: 1024,
          kind: DamageAttachmentKind.unsupported,
        ),
      ],
    ]);
    await tester.pumpWidget(reportApp(picker));

    Future<void> chooseGallery() async {
      await tester.ensureVisible(find.byKey(const Key('add_attachment')));
      await tester.tap(find.byKey(const Key('add_attachment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('source_gallery')));
      await tester.pumpAndSettle();
    }

    await chooseGallery();
    expect(
      find.text(
        'video-besar.mp4 lebih dari 20 MB. Pilih file yang lebih kecil, ya.',
      ),
      findsOneWidget,
    );

    await chooseGallery();
    expect(
      find.text(
        'Format laporan.pdf belum didukung. Pilih gambar atau video umum.',
      ),
      findsOneWidget,
    );
    expect(find.text('0/2 file'), findsOneWidget);
  });

  testWidgets('submit enables when all mandatory information is valid', (
    tester,
  ) async {
    await tester.pumpWidget(reportApp(_FakeMediaPicker()));

    ElevatedButton submitButton() => tester.widget<ElevatedButton>(
      find.byKey(const Key('submit_damage_report')),
    );

    expect(submitButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('damage_location_field')),
      'Gedung 2, Lantai 3',
    );
    await tester.enterText(
      find.byKey(const Key('damaged_item_field')),
      'AC Ruang Rapat',
    );
    await tester.ensureVisible(find.byKey(const Key('category_picker')));
    await tester.tap(find.byKey(const Key('category_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category_tata_udara')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('damage_description_field')),
      'AC tidak mengeluarkan udara dingin dan terdengar suara keras.',
    );
    await tester.enterText(
      find.byKey(const Key('damage_phone_field')),
      '081234567890',
    );
    await tester.pump();

    expect(submitButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('submit_damage_report')));
    await tester.pump();
    expect(find.text('Laporan kerusakan berhasil dikirim.'), findsOneWidget);
  });

  testWidgets('report header and first fields fit a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(reportApp(_FakeMediaPicker()));
    await tester.pump();

    expect(find.text('Laporan Kerusakan Gedung'), findsOneWidget);
    expect(find.byKey(const Key('damage_location_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
