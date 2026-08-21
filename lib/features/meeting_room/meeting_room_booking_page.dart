import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/auth_scope.dart';
import '../service_catalog/domain/service_catalog_failure.dart';
import '../service_catalog/domain/service_catalog_repository.dart';
import '../service_catalog/domain/service_submission_failure.dart';
import '../service_catalog/domain/service_submission_models.dart';
import 'meeting_room_models.dart';
import 'room_detail_sheet.dart';

class MeetingRoomBookingPage extends StatefulWidget {
  const MeetingRoomBookingPage({
    required this.user,
    required this.repository,
    super.key,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  final AppUser user;
  final ServiceCatalogRepository repository;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  @override
  State<MeetingRoomBookingPage> createState() => _MeetingRoomBookingPageState();
}

class _MeetingRoomBookingPageState extends State<MeetingRoomBookingPage> {
  final _participantController = TextEditingController();
  final _activityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hybridNoteController = TextEditingController();
  final _itNoteController = TextEditingController();
  final _meetingInfoKey = GlobalKey();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  MeetingRoom? _selectedRoom;
  MeetingType? _meetingType;
  String? _timeError;
  bool _participantTouched = false;
  bool _hybridMeeting = false;
  bool _itSupport = false;
  bool _isSubmitting = false;
  Map<String, List<String>> _submitFieldErrors = const {};
  List<MeetingRoom> _rooms = const [];
  bool _isLoadingRooms = false;
  String? _roomError;
  int _roomRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
    if (_isScheduleValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
    }
  }

  @override
  void dispose() {
    _participantController.dispose();
    _activityController.dispose();
    _phoneController.dispose();
    _hybridNoteController.dispose();
    _itNoteController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isScheduleValid {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      return false;
    }

    final selectedDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    return !selectedDay.isBefore(_today) &&
        _minutes(_endTime!) > _minutes(_startTime!);
  }

  int? get _participantCount => int.tryParse(_participantController.text);

  String? get _participantError {
    final backendError = _fieldError('jumlahPeserta');
    if (backendError != null) return backendError;
    if (!_participantTouched || _participantController.text.isEmpty) {
      return null;
    }
    final count = _participantCount;
    if (count == null || count < 1) {
      return 'Masukkan jumlah peserta minimal 1 orang.';
    }
    if (_selectedRoom != null && count > _selectedRoom!.maximumCapacity) {
      return 'Ruangan ini nyaman untuk maksimal ${_selectedRoom!.maximumCapacity} orang.';
    }
    return null;
  }

  bool get _isParticipantValid {
    final count = _participantCount;
    return count != null &&
        count > 0 &&
        _selectedRoom != null &&
        count <= _selectedRoom!.maximumCapacity;
  }

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && _phoneController.text.length <= 15;
  }

  bool get _canSubmit {
    return _isScheduleValid &&
        _selectedRoom != null &&
        _meetingType != null &&
        _isParticipantValid &&
        _activityController.text.trim().isNotEmpty &&
        _activityController.text.trim().length <= 255 &&
        _hybridNoteController.text.trim().length <= 255 &&
        _itNoteController.text.trim().length <= 255 &&
        _isPhoneValid;
  }

  String get _submitHint {
    if (!_isScheduleValid) return 'Lengkapi tanggal dan waktu penggunaan';
    if (_selectedRoom == null) return 'Pilih satu ruangan yang tersedia';
    if (_meetingType == null ||
        !_isParticipantValid ||
        _activityController.text.trim().isEmpty ||
        !_isPhoneValid) {
      return 'Lengkapi informasi rapat';
    }
    return 'Pemesanan siap diajukan';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            const _BookingHeader(),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('booking_scroll'),
                padding: const EdgeInsets.only(bottom: 136),
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionIntro(
                            number: '01',
                            title: 'Informasi pemesan',
                            subtitle: 'Pesanan ini akan diajukan atas namamu.',
                          ),
                          const SizedBox(height: 14),
                          _RequesterCard(user: widget.user),
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '02',
                            title: 'Atur jadwal',
                            subtitle: 'Tentukan kapan ruangan akan digunakan.',
                          ),
                          const SizedBox(height: 14),
                          _ScheduleCard(
                            dateLabel: _selectedDate == null
                                ? 'Pilih tanggal'
                                : _formatDate(_selectedDate!),
                            startLabel: _startTime == null
                                ? 'Jam mulai'
                                : _formatTime(_startTime!),
                            endLabel: _endTime == null
                                ? 'Jam selesai'
                                : _formatTime(_endTime!),
                            error: _scheduleError,
                            onPickDate: _pickDate,
                            onPickStart: _pickStartTime,
                            onPickEnd: _pickEndTime,
                          ),
                          const SizedBox(height: 22),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                ),
                            child: _isScheduleValid
                                ? _buildRoomAvailability()
                                : const _ScheduleGate(
                                    key: ValueKey('schedule_gate'),
                                  ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                ),
                            child: _selectedRoom == null
                                ? const SizedBox.shrink()
                                : Column(
                                    key: const ValueKey('meeting_sections'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        key: _meetingInfoKey,
                                        height: 32,
                                      ),
                                      const _SectionIntro(
                                        number: '04',
                                        title: 'Informasi rapat',
                                        subtitle: 'Bantu kami menyiapkan ruang dengan tepat.',
                                      ),
                                      const SizedBox(height: 14),
                                      _MeetingInformationPanel(
                                        selectedType: _meetingType,
                                        participantController:
                                            _participantController,
                                        activityController: _activityController,
                                        phoneController: _phoneController,
                                        participantError: _participantError,
                                        meetingTypeError: _fieldError(
                                          'jenisRapat',
                                        ),
                                        activityError: _fieldError('purpose'),
                                        phoneError: _fieldError('contact'),
                                        onTypeChanged: (value) => setState(() {
                                          _meetingType = value;
                                          _clearFieldErrors(['jenisRapat']);
                                        }),
                                        onParticipantChanged: (_) =>
                                            setState(() {
                                              _participantTouched = true;
                                              _clearFieldErrors([
                                                'jumlahPeserta',
                                              ]);
                                            }),
                                        onActivityChanged: (_) => setState(
                                          () => _clearFieldErrors(['purpose']),
                                        ),
                                        onPhoneChanged: (_) => setState(
                                          () => _clearFieldErrors(['contact']),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      const _SectionIntro(
                                        number: '05',
                                        title: 'Dukungan',
                                        subtitle: 'Pilih bantuan tambahan jika diperlukan.',
                                      ),
                                      const SizedBox(height: 14),
                                      _SupportPanel(
                                        hybridMeeting: _hybridMeeting,
                                        itSupport: _itSupport,
                                        hybridNoteController:
                                            _hybridNoteController,
                                        itNoteController: _itNoteController,
                                        onHybridChanged: () => setState(
                                          () =>
                                              _hybridMeeting = !_hybridMeeting,
                                        ),
                                        onItChanged: () => setState(
                                          () => _itSupport = !_itSupport,
                                        ),
                                        hybridError: _fieldError(
                                          'hybridDetail',
                                        ),
                                        itError: _fieldError('itSupportDetail'),
                                        onHybridNoteChanged: (_) => setState(
                                          () => _clearFieldErrors([
                                            'hybridDetail',
                                          ]),
                                        ),
                                        onItNoteChanged: (_) => setState(
                                          () => _clearFieldErrors([
                                            'itSupportDetail',
                                          ]),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _SubmitBar(
          enabled: _canSubmit && !_isSubmitting,
          loading: _isSubmitting,
          hint: _isSubmitting ? 'Mengirim pemesanan…' : _submitHint,
          onSubmit: _submit,
        ),
      ),
    );
  }

  Widget _buildRoomAvailability() {
    if (_isLoadingRooms) {
      return const _RoomCatalogMessage(
        key: ValueKey('room_loading'),
        icon: Icons.sync_rounded,
        message: 'Memeriksa ketersediaan ruangan…',
        loading: true,
      );
    }
    if (_roomError != null) {
      return _RoomCatalogMessage(
        key: const ValueKey('room_error'),
        icon: Icons.cloud_off_outlined,
        message: _roomError!,
        actionLabel: 'Coba lagi',
        onAction: _loadRooms,
      );
    }
    if (_rooms.isEmpty) {
      return const _RoomCatalogMessage(
        key: ValueKey('room_empty'),
        icon: Icons.event_busy_outlined,
        message: 'Tidak ada ruangan yang tersedia untuk jadwal ini.',
      );
    }
    return _RoomAvailabilitySection(
      key: const ValueKey('room_list'),
      rooms: _rooms,
      selectedRoom: _selectedRoom,
      onSelect: _selectRoom,
      onDetail: _showRoomDetail,
      fieldError:
          _fieldError('room_code') ??
          _fieldError('room_name') ??
          _fieldError('room'),
    );
  }

  String? get _scheduleError {
    final backendError =
        _fieldError('date') ??
        _fieldError('startTime') ??
        _fieldError('endTime');
    if (backendError != null) return backendError;
    if (_selectedDate != null) {
      final day = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      if (day.isBefore(_today)) {
        return 'Pilih hari ini atau tanggal setelahnya, ya.';
      }
    }
    return _timeError;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null && !_selectedDate!.isBefore(_today)
          ? _selectedDate!
          : _today,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 365)),
      helpText: 'TANGGAL PENGGUNAAN',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _selectedRoom = null;
      _timeError = null;
      _clearFieldErrors(['date']);
    });
    _refreshRoomsIfScheduleValid();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'JAM MULAI',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _startTime = picked;
      _selectedRoom = null;
      if (_endTime != null && _minutes(_endTime!) <= _minutes(picked)) {
        _endTime = null;
        _timeError = 'Pilih jam selesai setelah jam mulai, ya.';
      } else {
        _timeError = null;
      }
      _clearFieldErrors(['startTime', 'endTime']);
    });
    _refreshRoomsIfScheduleValid();
  }

  Future<void> _pickEndTime() async {
    if (_startTime == null) {
      setState(() => _timeError = 'Pilih jam mulai terlebih dahulu, ya.');
      return;
    }

    final defaultEndMinutes = (_minutes(_startTime!) + 60).clamp(0, 1439);
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _endTime ??
          TimeOfDay(
            hour: defaultEndMinutes ~/ 60,
            minute: defaultEndMinutes % 60,
          ),
      helpText: 'JAM SELESAI',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedRoom = null;
      if (_minutes(picked) <= _minutes(_startTime!)) {
        _endTime = null;
        _timeError = 'Jam selesai perlu lebih akhir dari jam mulai.';
      } else {
        _endTime = picked;
        _timeError = null;
      }
      _clearFieldErrors(['endTime']);
    });
    _refreshRoomsIfScheduleValid();
  }

  void _refreshRoomsIfScheduleValid() {
    if (_isScheduleValid) {
      _loadRooms();
    } else {
      _roomRequestGeneration += 1;
      setState(() {
        _rooms = const [];
        _roomError = null;
        _isLoadingRooms = false;
      });
    }
  }

  Future<void> _loadRooms() async {
    if (!_isScheduleValid) return;
    final requestGeneration = ++_roomRequestGeneration;
    setState(() {
      _isLoadingRooms = true;
      _roomError = null;
      _selectedRoom = null;
    });

    try {
      final rooms = await widget.repository.getAvailableRooms(
        date: _selectedDate!,
        startHour: _startTime!.hour,
        startMinute: _startTime!.minute,
        endHour: _endTime!.hour,
        endMinute: _endTime!.minute,
      );
      if (!mounted || requestGeneration != _roomRequestGeneration) return;
      setState(() => _rooms = rooms);
    } on ServiceCatalogFailure catch (failure) {
      if (!mounted || requestGeneration != _roomRequestGeneration) return;
      if (failure.type == ServiceCatalogFailureType.unauthorized) {
        await AuthScope.of(context).logout();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _roomError = failure.message);
    } catch (_) {
      if (!mounted || requestGeneration != _roomRequestGeneration) return;
      setState(() => _roomError = 'Data ruangan belum dapat dimuat.');
    } finally {
      if (mounted && requestGeneration == _roomRequestGeneration) {
        setState(() => _isLoadingRooms = false);
      }
    }
  }

  void _selectRoom(MeetingRoom room) {
    if (!room.isAvailable) return;
    setState(() {
      _selectedRoom = room;
      _clearFieldErrors(['room_code', 'room']);
      _participantTouched = _participantController.text.isNotEmpty;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final infoContext = _meetingInfoKey.currentContext;
      if (infoContext != null) {
        Scrollable.ensureVisible(
          infoContext,
          alignment: 0.05,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showRoomDetail(MeetingRoom room) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      builder: (context) => RoomDetailSheet(room: room),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
      _submitFieldErrors = const {};
    });
    try {
      final response = await widget.repository.submitRoomBooking(
        RoomBookingSubmission(
          roomCode: _selectedRoom!.code,
          roomName: _selectedRoom!.name,
          date: _apiDate(_selectedDate!),
          startTime: _apiTime(_startTime!),
          endTime: _apiTime(_endTime!),
          purpose: _activityController.text.trim(),
          participantCount: _participantController.text.trim(),
          contact: _phoneController.text.trim(),
          meetingType: _meetingType!.name,
          needItSupport: _itSupport,
          itSupportDetail: _itSupport
              ? _nullableText(_itNoteController.text)
              : null,
          isHybrid: _hybridMeeting,
          hybridDetail: _hybridMeeting
              ? _nullableText(_hybridNoteController.text)
              : null,
        ),
      );
      if (!mounted) return;
      _resetAfterSuccess();
      _showSubmitMessage(_successMessage(response), success: true);
    } on ServiceSubmissionFailure catch (failure) {
      if (!mounted) return;
      if (failure.type == ServiceSubmissionFailureType.unauthorized) {
        await AuthScope.of(context).logout();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _submitFieldErrors = failure.fieldErrors);
      _showSubmitMessage(failure.primaryMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetAfterSuccess() {
    setState(() {
      _selectedRoom = null;
      _meetingType = null;
      _hybridMeeting = false;
      _itSupport = false;
      _participantTouched = false;
      _submitFieldErrors = const {};
      _participantController.clear();
      _activityController.clear();
      _phoneController.clear();
      _hybridNoteController.clear();
      _itNoteController.clear();
    });
  }

  String? _fieldError(String field) => _submitFieldErrors[field]?.firstOrNull;

  String _successMessage(ServiceSubmitResponse response) {
    final details = [
      if (response.referenceCode != null)
        'Nomor booking: ${response.referenceCode}',
      if (response.status != null) 'Status: ${response.status}',
    ];
    if (details.isEmpty) return response.message;
    return '${response.message} ${details.join('. ')}.';
  }

  void _clearFieldErrors(Iterable<String> fields) {
    if (_submitFieldErrors.isEmpty) return;
    final next = Map<String, List<String>>.from(_submitFieldErrors);
    for (final field in fields) {
      next.remove(field);
    }
    _submitFieldErrors = next;
  }

  void _showSubmitMessage(String message, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline,
                color: success ? AppColors.mint : AppColors.coral,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
  }

  static String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _apiTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime date) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FAFF), Color(0xFFD2F0FD)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 20, 20),
          child: Row(
            children: [
              IconButton.filled(
                key: const Key('booking_back'),
                tooltip: 'Kembali',
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.78),
                  foregroundColor: AppColors.primaryDeep,
                  fixedSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buat pesanan baru',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDeep.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pemesanan Ruang Rapat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryStrong,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2450AEDA),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            number,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.primaryDeep),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequesterCard extends StatelessWidget {
  const _RequesterCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryStrong],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.initials,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        user.unitKerja,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Terverifikasi',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.mint, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.dateLabel,
    required this.startLabel,
    required this.endLabel,
    required this.error,
    required this.onPickDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final String dateLabel;
  final String startLabel;
  final String endLabel;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _ScheduleTile(
            key: const Key('date_picker'),
            icon: Icons.calendar_today_rounded,
            eyebrow: 'Tanggal penggunaan',
            value: dateLabel,
            onTap: onPickDate,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScheduleTile(
                  key: const Key('start_time_picker'),
                  icon: Icons.schedule_rounded,
                  eyebrow: 'Mulai',
                  value: startLabel,
                  compact: true,
                  onTap: onPickStart,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(width: 18, height: 1.5, color: AppColors.line),
              ),
              Expanded(
                child: _ScheduleTile(
                  key: const Key('end_time_picker'),
                  icon: Icons.more_time_rounded,
                  eyebrow: 'Selesai',
                  value: endLabel,
                  compact: true,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: error == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(error),
                    padding: const EdgeInsets.fromLTRB(4, 11, 4, 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.coral,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            error!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.coral),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.value,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String eyebrow;
  final String value;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryPale,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 13,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryStrong, size: 19),
              ),
              SizedBox(width: compact ? 8 : 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: compact ? 10 : 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontSize: compact ? 12 : 14),
                    ),
                  ],
                ),
              ),
              if (!compact)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleGate extends StatelessWidget {
  const _ScheduleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              color: AppColors.primaryStrong,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ruangan tersedia akan muncul setelah jadwalmu lengkap.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.primaryDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCatalogMessage extends StatelessWidget {
  const _RoomCatalogMessage({
    required this.icon,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionIntro(
          number: '03',
          title: 'Pilih ruangan',
          subtitle: 'Ketersediaan sesuai jadwal yang kamu pilih.',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                )
              else
                Icon(icon, color: AppColors.primaryStrong, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.primaryDeep),
                ),
              ),
              if (onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomAvailabilitySection extends StatelessWidget {
  const _RoomAvailabilitySection({
    super.key,
    required this.rooms,
    required this.selectedRoom,
    required this.onSelect,
    required this.onDetail,
    this.fieldError,
  });

  final List<MeetingRoom> rooms;
  final MeetingRoom? selectedRoom;
  final ValueChanged<MeetingRoom> onSelect;
  final ValueChanged<MeetingRoom> onDetail;
  final String? fieldError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionIntro(
          number: '03',
          title: 'Pilih ruangan',
          subtitle: 'Ketersediaan sesuai jadwal yang kamu pilih.',
        ),
        const SizedBox(height: 14),
        if (fieldError != null) ...[
          Text(
            fieldError!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.coral),
          ),
          const SizedBox(height: 10),
        ],
        ...rooms.indexed.map(
          (entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.$1 == rooms.length - 1 ? 0 : 12,
            ),
            child: _RoomCard(
              room: entry.$2,
              selected: selectedRoom == entry.$2,
              onSelect: () => onSelect(entry.$2),
              onDetail: () => onDetail(entry.$2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.selected,
    required this.onSelect,
    required this.onDetail,
  });

  final MeetingRoom room;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final statusColor = room.isAvailable ? AppColors.mint : AppColors.coral;
    final statusBackground = room.isAvailable
        ? AppColors.mintSoft
        : AppColors.coralSoft;

    return AnimatedContainer(
      key: Key('room_${room.id.toLowerCase()}'),
      duration: const Duration(milliseconds: 190),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPale : AppColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: selected ? AppColors.primaryStrong : AppColors.line,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x1854BDF2),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: room.isAvailable ? onSelect : null,
          borderRadius: BorderRadius.circular(23),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primarySoft
                            : statusBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        selected
                            ? Icons.check_rounded
                            : Icons.meeting_room_outlined,
                        color: selected ? AppColors.primaryStrong : statusColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${room.capacity} orang · Maks. ${room.maximumCapacityLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        room.isAvailable ? 'Tersedia' : 'Telah Dipesan',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: statusColor, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                if (!room.isAvailable) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      room.bookedInformation,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: Key('detail_${room.id.toLowerCase()}'),
                    onPressed: onDetail,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryStrong,
                      minimumSize: const Size(48, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_outward_rounded, size: 17),
                    label: const Text('Detail'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingInformationPanel extends StatelessWidget {
  const _MeetingInformationPanel({
    required this.selectedType,
    required this.participantController,
    required this.activityController,
    required this.phoneController,
    required this.participantError,
    required this.meetingTypeError,
    required this.activityError,
    required this.phoneError,
    required this.onTypeChanged,
    required this.onParticipantChanged,
    required this.onActivityChanged,
    required this.onPhoneChanged,
  });

  final MeetingType? selectedType;
  final TextEditingController participantController;
  final TextEditingController activityController;
  final TextEditingController phoneController;
  final String? participantError;
  final String? meetingTypeError;
  final String? activityError;
  final String? phoneError;
  final ValueChanged<MeetingType> onTypeChanged;
  final ValueChanged<String> onParticipantChanged;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<String> onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jenis rapat', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: MeetingType.values
                .map(
                  (type) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type == MeetingType.internal ? 8 : 0,
                      ),
                      child: _ChoiceSegment(
                        key: Key('meeting_type_${type.name}'),
                        label: type.label,
                        selected: selectedType == type,
                        onTap: () => onTypeChanged(type),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (meetingTypeError != null) ...[
            const SizedBox(height: 7),
            Text(
              meetingTypeError!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.coral),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            key: const Key('participant_field'),
            controller: participantController,
            onChanged: onParticipantChanged,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Jumlah peserta',
              hintText: 'Contoh: 8',
              prefixIcon: const Icon(Icons.groups_2_outlined),
              suffixText: 'orang',
              errorText: participantError,
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const Key('activity_field'),
            controller: activityController,
            onChanged: onActivityChanged,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Kegiatan',
              hintText: 'Nama atau judul kegiatan',
              prefixIcon: const Icon(Icons.edit_calendar_outlined),
              errorText: activityError,
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const Key('phone_field'),
            controller: phoneController,
            onChanged: onPhoneChanged,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
            decoration: InputDecoration(
              labelText: 'No. HP',
              hintText: 'Nomor contact person',
              prefixIcon: const Icon(Icons.phone_outlined),
              errorText: phoneError,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSegment extends StatelessWidget {
  const _ChoiceSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? AppColors.primaryStrong : AppColors.line,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? AppColors.primaryStrong
                      : AppColors.inkMuted,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({
    required this.hybridMeeting,
    required this.itSupport,
    required this.hybridNoteController,
    required this.itNoteController,
    required this.onHybridChanged,
    required this.onItChanged,
    required this.hybridError,
    required this.itError,
    required this.onHybridNoteChanged,
    required this.onItNoteChanged,
  });

  final bool hybridMeeting;
  final bool itSupport;
  final TextEditingController hybridNoteController;
  final TextEditingController itNoteController;
  final VoidCallback onHybridChanged;
  final VoidCallback onItChanged;
  final String? hybridError;
  final String? itError;
  final ValueChanged<String> onHybridNoteChanged;
  final ValueChanged<String> onItNoteChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SupportOption(
                  key: const Key('hybrid_option'),
                  icon: Icons.video_camera_front_outlined,
                  label: 'Rapat Hybrid',
                  selected: hybridMeeting,
                  onTap: onHybridChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SupportOption(
                  key: const Key('it_option'),
                  icon: Icons.computer_rounded,
                  label: 'Dukungan IT',
                  selected: itSupport,
                  onTap: onItChanged,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: !hybridMeeting && !itSupport
                ? Padding(
                    key: const ValueKey('support_hint'),
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      'Opsional · pilih bila rapat membutuhkan dukungan khusus.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    key: ValueKey('$hybridMeeting-$itSupport'),
                    children: [
                      if (hybridMeeting) ...[
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('hybrid_note_field'),
                          controller: hybridNoteController,
                          onChanged: onHybridNoteChanged,
                          minLines: 2,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Catatan Rapat Hybrid (Optional)',
                            hintText: 'Contoh: membutuhkan tautan meeting',
                            alignLabelWithHint: true,
                            errorText: hybridError,
                          ),
                        ),
                      ],
                      if (itSupport) ...[
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('it_note_field'),
                          controller: itNoteController,
                          onChanged: onItNoteChanged,
                          minLines: 2,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Catatan Dukungan IT (Optional)',
                            hintText: 'Jelaskan bantuan yang dibutuhkan',
                            alignLabelWithHint: true,
                            errorText: itError,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? AppColors.primaryStrong : AppColors.line,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      color: selected
                          ? AppColors.primaryStrong
                          : AppColors.inkMuted,
                      size: 22,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryStrong
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryStrong
                              : AppColors.line,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.enabled,
    required this.hint,
    required this.onSubmit,
    required this.loading,
  });

  final bool enabled;
  final String hint;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F173B4E),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 11, 20, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Row(
                  key: ValueKey(hint),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      enabled
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 15,
                      color: enabled ? AppColors.mint : AppColors.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: enabled ? AppColors.mint : AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('submit_booking'),
                  onPressed: enabled && !loading ? onSubmit : null,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 19),
                  label: Text(loading ? 'Mengirim…' : 'Ajukan Pemesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
