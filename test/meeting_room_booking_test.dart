import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swp_mandala_mobile/core/theme/app_theme.dart';
import 'package:swp_mandala_mobile/features/meeting_room/meeting_room_booking_page.dart';

import 'test_helpers.dart';

void main() {
  Widget bookingWithValidSchedule() {
    return MaterialApp(
      theme: AppTheme.light,
      home: MeetingRoomBookingPage(
        user: testUser,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        initialStartTime: const TimeOfDay(hour: 9, minute: 0),
        initialEndTime: const TimeOfDay(hour: 12, minute: 0),
      ),
    );
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
        home: const MeetingRoomBookingPage(user: testUser),
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
    expect(find.text('Telah Dipesan'), findsNWidgets(2));
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
    await tester.pumpWidget(bookingWithValidSchedule());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('room_buton')));
    await tester.tap(find.byKey(const Key('room_buton')));
    await tester.pumpAndSettle();

    ElevatedButton submitButton() =>
        tester.widget<ElevatedButton>(find.byKey(const Key('submit_booking')));

    expect(submitButton().onPressed, isNull);

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

    expect(submitButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('submit_booking')));
    await tester.pump();
    expect(
      find.text('Pemesanan Ruang Rapat Buton berhasil diajukan.'),
      findsOneWidget,
    );
  });

  testWidgets('booking header and schedule fit a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MeetingRoomBookingPage(user: testUser),
      ),
    );

    expect(find.text('Pemesanan Ruang Rapat'), findsOneWidget);
    expect(find.byKey(const Key('date_picker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
