import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/meeting_room/meeting_room_models.dart';
import 'package:swp_mandala_mobile/features/meeting_room/meeting_room_booking_page.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_submission_failure.dart';
import 'package:swp_mandala_mobile/features/service_catalog/domain/service_submission_models.dart';

import 'test_helpers.dart';

void main() {
  Widget bookingWithValidSchedule({TestServiceCatalogRepository? repository}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: MeetingRoomBookingPage(
        user: testUser,
        repository: repository ?? TestServiceCatalogRepository(),
        initialDate: DateTime.now().add(const Duration(days: 1)),
        initialStartTime: const TimeOfDay(hour: 9, minute: 0),
        initialEndTime: const TimeOfDay(hour: 12, minute: 0),
      ),
    );
  }

  Future<void> fillValidBooking(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('room_buton')));
    await tester.tap(find.byKey(const Key('room_buton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('meeting_type_internal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meeting_type_internal')));
    await tester.enterText(find.byKey(const Key('participant_field')), '8');
    await tester.enterText(
      find.byKey(const Key('activity_field')),
      'Koordinasi program kerja',
    );
    await tester.enterText(
      find.byKey(const Key('phone_field')),
      '081234567890',
    );
    await tester.pump();
  }

  testWidgets('meeting room service opens the booking page from home', (
    tester,
  ) async {
    await tester.pumpWidget(homeTestApp());

    await tester.tap(find.byKey(const Key('service_0')));
    await tester.pumpAndSettle();

    expect(find.text('Pemesanan Ruang Rapat'), findsWidgets);
    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Biro Umum'), findsOneWidget);
  });

  testWidgets('room list stays hidden until schedule is complete', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MeetingRoomBookingPage(
          user: testUser,
          repository: TestServiceCatalogRepository(),
        ),
      ),
    );

    expect(find.text('Ruang Rapat Buton'), findsNothing);
    expect(
      find.text('Ruangan tersedia akan muncul setelah jadwalmu lengkap.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('end_time_picker')));
    await tester.pump();

    expect(find.text('Pilih jam mulai terlebih dahulu, ya.'), findsOneWidget);
  });

  testWidgets(
    'valid schedule fetches real room states and all booked details',
    (tester) async {
      final repository = TestServiceCatalogRepository(
        rooms: const [
          MeetingRoom(
            id: 'RPT-2V4N9',
            name: 'Ruang Rapat Buton API',
            code: 'RPT-2V4N9',
            location: 'Gedung Sekretariat I Lantai 4',
            capacity: '26+1',
            maximumCapacityLabel: '26+1',
            maximumCapacity: 27,
            isAvailable: true,
            islandName: 'Pulau Buton, Sulawesi Tenggara',
            philosophy: 'Deskripsi filosofi dari API.',
            bookedSlots: [],
            bookedByBureaus: [],
            facilities: ['tv-led'],
            imageUrl: 'http://src.test/files/room.jpg',
            descriptionImageUrl: 'http://src.test/files/island.png',
          ),
          MeetingRoom(
            id: 'RPT-ISYWN',
            name: 'Ruang Rapat Enggano',
            code: 'RPT-ISYWN',
            location: 'Gedung Sekretariat II Lantai 1',
            capacity: '34+1',
            maximumCapacityLabel: '50+1',
            maximumCapacity: 51,
            isAvailable: false,
            islandName: 'Pulau Enggano, Bengkulu',
            philosophy: 'Permata terluar Indonesia.',
            bookedSlots: ['09:00 - 15:00', '16:00 - 17:00'],
            bookedByBureaus: ['Biro A', 'Biro B'],
            facilities: ['tv-led', 'kamera'],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MeetingRoomBookingPage(
            user: testUser,
            repository: repository,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            initialStartTime: const TimeOfDay(hour: 8, minute: 0),
            initialEndTime: const TimeOfDay(hour: 10, minute: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.roomCalls, 1);
      expect(find.text('Ruang Rapat Buton API'), findsOneWidget);
      expect(find.text('Ruang Rapat Enggano'), findsOneWidget);
      expect(
        find.textContaining('09:00 - 15:00, 16:00 - 17:00'),
        findsOneWidget,
      );
      expect(find.textContaining('Biro A, Biro B'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('room_rpt-isywn')));
      await tester.tap(find.byKey(const Key('room_rpt-isywn')));
      await tester.pump();
      expect(find.byKey(const Key('participant_field')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('room_rpt-2v4n9')));
      await tester.tap(find.byKey(const Key('room_rpt-2v4n9')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('participant_field')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('detail_rpt-2v4n9')));
      await tester.tap(find.byKey(const Key('detail_rpt-2v4n9')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Image>(find.byType(Image))
            .any((image) => image.image is NetworkImage),
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.text('Deskripsi filosofi dari API.'),
        280,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Deskripsi filosofi dari API.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('tv led'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('tv led'), findsOneWidget);
    },
  );

  testWidgets('room detail opens in a contextual bottom sheet', (tester) async {
    await tester.pumpWidget(bookingWithValidSchedule());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('detail_buton')));
    await tester.tap(find.byKey(const Key('detail_buton')));
    await tester.pumpAndSettle();

    expect(find.text('Detail Ruangan'), findsOneWidget);
    expect(find.text('Gedung 2, Lantai 3'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Pulau Buton'),
      280,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Pulau Buton'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('room selection reveals meeting information and support', (
    tester,
  ) async {
    await tester.pumpWidget(bookingWithValidSchedule());
    await tester.pumpAndSettle();

    expect(find.text('Ruang Rapat Buton'), findsOneWidget);
    expect(find.text('Telah Dipesan'), findsOneWidget);
    expect(find.byKey(const Key('participant_field')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('room_buton')));
    await tester.tap(find.byKey(const Key('room_buton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('participant_field')), findsOneWidget);
    expect(find.byKey(const Key('hybrid_option')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('participant_field')), '20');
    await tester.pump();
    expect(
      find.text('Ruangan ini nyaman untuk maksimal 14 orang.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('hybrid_option')));
    await tester.tap(find.byKey(const Key('hybrid_option')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hybrid_note_field')), findsOneWidget);
    expect(find.byKey(const Key('it_note_field')), findsNothing);
  });

  testWidgets('submit activates only after mandatory fields are valid', (
    tester,
  ) async {
    final repository = TestServiceCatalogRepository();
    await tester.pumpWidget(bookingWithValidSchedule(repository: repository));
    await tester.pumpAndSettle();

    ElevatedButton submitButton() =>
        tester.widget<ElevatedButton>(find.byKey(const Key('submit_booking')));

    expect(submitButton().onPressed, isNull);

    await fillValidBooking(tester);

    expect(submitButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('submit_booking')));
    await tester.pump();
    expect(
      find.text('Pemesanan Ruang Rapat Buton berhasil diajukan.'),
      findsOneWidget,
    );
    expect(repository.roomSubmitCalls, 1);
    expect(repository.submittedRoom?.toJson(), {
      'room_code': 'RPT-BUTON',
      'room_name': 'Ruang Rapat Buton',
      'date': isA<String>(),
      'startTime': '09:00',
      'endTime': '12:00',
      'purpose': 'Koordinasi program kerja',
      'jumlahPeserta': '8',
      'contact': '081234567890',
      'jenisRapat': 'internal',
      'needItSupport': false,
      'itSupportDetail': null,
      'isHybrid': false,
      'hybridDetail': null,
    });
  });

  testWidgets('backend field error stays attached to the matching room field', (
    tester,
  ) async {
    final repository = TestServiceCatalogRepository(
      roomSubmitError: const ServiceSubmissionFailure(
        type: ServiceSubmissionFailureType.validation,
        message: 'The given data was invalid.',
        fieldErrors: {
          'purpose': ['Kegiatan sudah melebihi 255 karakter.'],
        },
      ),
    );
    await tester.pumpWidget(bookingWithValidSchedule(repository: repository));
    await tester.pumpAndSettle();
    await fillValidBooking(tester);

    await tester.tap(find.byKey(const Key('submit_booking')));
    await tester.pump();

    expect(find.text('Kegiatan sudah melebihi 255 karakter.'), findsWidgets);
    expect(find.text('The given data was invalid.'), findsNothing);
  });

  testWidgets('room request cannot be submitted twice while loading', (
    tester,
  ) async {
    final completer = Completer<ServiceSubmitResponse>();
    final repository = TestServiceCatalogRepository(
      roomSubmitFuture: completer.future,
    );
    await tester.pumpWidget(bookingWithValidSchedule(repository: repository));
    await tester.pumpAndSettle();
    await fillValidBooking(tester);

    await tester.tap(find.byKey(const Key('submit_booking')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit_booking')));
    await tester.pump();

    expect(repository.roomSubmitCalls, 1);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('submit_booking')))
          .onPressed,
      isNull,
    );

    completer.complete(
      const ServiceSubmitResponse(message: 'Berhasil dari backend.'),
    );
    await tester.pump();
    expect(find.text('Berhasil dari backend.'), findsOneWidget);
  });

  testWidgets('booking header and schedule fit a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MeetingRoomBookingPage(
          user: testUser,
          repository: TestServiceCatalogRepository(),
        ),
      ),
    );

    expect(find.text('Pemesanan Ruang Rapat'), findsOneWidget);
    expect(find.byKey(const Key('date_picker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
