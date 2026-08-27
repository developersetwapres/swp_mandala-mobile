import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/auth_scope.dart';
import '../service_catalog/domain/service_catalog_failure.dart';
import '../service_catalog/domain/service_catalog_repository.dart';
import '../service_catalog/domain/service_submission_failure.dart';
import '../service_catalog/domain/service_submission_models.dart';
import 'damage_category_sheet.dart';
import 'damage_media_source_sheet.dart';
import 'damage_report_models.dart';
import 'image_picker_damage_media_picker.dart';

class DamageReportPage extends StatefulWidget {
  const DamageReportPage({
    required this.user,
    required this.repository,
    super.key,
    this.mediaPicker,
  });

  final AppUser user;
  final ServiceCatalogRepository repository;
  final DamageMediaPicker? mediaPicker;

  @override
  State<DamageReportPage> createState() => _DamageReportPageState();
}

class _DamageReportPageState extends State<DamageReportPage> {
  static const int _maximumFiles = 2;
  static const int _maximumImageSize = 5 * 1024 * 1024;
  static const int _maximumVideoSize = 20 * 1024 * 1024;

  final _locationController = TextEditingController();
  final _itemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  final _locationFocus = FocusNode();
  final _itemFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _phoneFocus = FocusNode();

  late final DamageMediaPicker _mediaPicker;
  final List<DamageAttachment> _attachments = [];

  DamageCategory? _selectedCategory;
  String? _attachmentError;
  bool _isPickingMedia = false;
  bool _locationTouched = false;
  bool _itemTouched = false;
  bool _descriptionTouched = false;
  bool _phoneTouched = false;
  List<DamageCategory> _categories = const [];
  bool _isLoadingCategories = true;
  String? _categoryError;
  bool _isSubmitting = false;
  Map<String, List<String>> _submitFieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _mediaPicker = widget.mediaPicker ?? ImagePickerDamageMediaPicker();
    _locationFocus.addListener(() => _markTouchedOnBlur('location'));
    _itemFocus.addListener(() => _markTouchedOnBlur('item'));
    _descriptionFocus.addListener(() => _markTouchedOnBlur('description'));
    _phoneFocus.addListener(() => _markTouchedOnBlur('phone'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverLostMedia();
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _itemController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _locationFocus.dispose();
    _itemFocus.dispose();
    _descriptionFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && _phoneController.text.length <= 15;
  }

  bool get _canSubmit {
    return _locationController.text.trim().isNotEmpty &&
        _itemController.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _descriptionController.text.trim().isNotEmpty &&
        _locationController.text.trim().length <= 255 &&
        _itemController.text.trim().length <= 255 &&
        _descriptionController.text.trim().length <= 255 &&
        _attachments.isNotEmpty &&
        _isPhoneValid;
  }

  String get _submitHint {
    if (_locationController.text.trim().isEmpty) {
      return 'Lengkapi lokasi kerusakan';
    }
    if (_itemController.text.trim().isEmpty) {
      return 'Isi nama item yang rusak';
    }
    if (_selectedCategory == null) return 'Pilih kategori kerusakan';
    if (_descriptionController.text.trim().isEmpty) {
      return 'Ceritakan kondisi kerusakan';
    }
    if (_attachments.isEmpty) return 'Tambahkan dokumentasi kerusakan';
    if (!_isPhoneValid) return 'Lengkapi nomor HP yang dapat dihubungi';
    return 'Laporan siap dikirim';
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
            const _DamageReportHeader(),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('damage_report_scroll'),
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
                            title: 'Informasi pelapor',
                            subtitle: 'Laporan akan dikirim atas namamu.',
                          ),
                          const SizedBox(height: 14),
                          _ReporterCard(user: widget.user),
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '02',
                            title: 'Di mana kerusakannya?',
                            subtitle:
                                'Bantu tim menemukan masalah lebih cepat.',
                          ),
                          const SizedBox(height: 14),
                          _DamageIdentityPanel(
                            locationController: _locationController,
                            itemController: _itemController,
                            locationFocus: _locationFocus,
                            itemFocus: _itemFocus,
                            locationError:
                                _fieldError('location') ??
                                (_locationTouched &&
                                        _locationController.text.trim().isEmpty
                                    ? 'Lokasinya perlu diisi agar mudah ditemukan.'
                                    : null),
                            itemError:
                                _fieldError('damageType') ??
                                (_itemTouched &&
                                        _itemController.text.trim().isEmpty
                                    ? 'Tuliskan item yang mengalami kerusakan.'
                                    : null),
                            categoryError: _fieldError('kategori'),
                            category: _selectedCategory,
                            onLocationChanged: (_) =>
                                setState(() => _clearFieldErrors(['location'])),
                            onItemChanged: (_) => setState(
                              () => _clearFieldErrors(['damageType']),
                            ),
                            onChooseCategory: _showCategoryPicker,
                          ),
                          if (_isLoadingCategories ||
                              _categoryError != null ||
                              (!_isLoadingCategories &&
                                  _categories.isEmpty)) ...[
                            const SizedBox(height: 12),
                            _CatalogLoadNotice(
                              loading: _isLoadingCategories,
                              message:
                                  _categoryError ??
                                  (_categories.isEmpty
                                      ? 'Kategori kerusakan belum tersedia.'
                                      : ''),
                              onRetry: _categoryError == null
                                  ? null
                                  : () => _loadCategories(forceRefresh: true),
                            ),
                          ],
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '03',
                            title: 'Ceritakan kondisinya',
                            subtitle:
                                'Jelaskan gejala yang terlihat atau terdengar.',
                          ),
                          const SizedBox(height: 14),
                          _DescriptionPanel(
                            controller: _descriptionController,
                            focusNode: _descriptionFocus,
                            error:
                                _fieldError('description') ??
                                (_descriptionTouched &&
                                        _descriptionController.text
                                            .trim()
                                            .isEmpty
                                    ? 'Tambahkan sedikit keterangan tentang kerusakan.'
                                    : null),
                            onChanged: (_) => setState(
                              () => _clearFieldErrors(['description']),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '04',
                            title: 'Foto atau video',
                            subtitle: 'Opsional, tetapi membantu pemeriksaan lebih cepat.',
                          ),
                          const SizedBox(height: 14),
                          _AttachmentPanel(
                            attachments: _attachments,
                            error: _attachmentError ?? _fieldError('photos'),
                            isPicking: _isPickingMedia,
                            onAdd: _showMediaSourcePicker,
                            onRemove: _removeAttachment,
                          ),
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '05',
                            title: 'Kontak pelapor',
                            subtitle: 'Nomor ini digunakan bila tim perlu konfirmasi.',
                          ),
                          const SizedBox(height: 14),
                          _PhonePanel(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            error:
                                _fieldError('contact') ??
                                (_phoneTouched && !_isPhoneValid
                                    ? 'Masukkan nomor HP aktif, 9–15 karakter.'
                                    : null),
                            onChanged: (_) =>
                                setState(() => _clearFieldErrors(['contact'])),
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
          hint: _isSubmitting ? 'Mengirim laporan…' : _submitHint,
          onSubmit: _submit,
        ),
      ),
    );
  }

  void _markTouchedOnBlur(String field) {
    final lostFocus = switch (field) {
      'location' => !_locationFocus.hasFocus,
      'item' => !_itemFocus.hasFocus,
      'description' => !_descriptionFocus.hasFocus,
      _ => !_phoneFocus.hasFocus,
    };
    if (!lostFocus || !mounted) return;

    setState(() {
      switch (field) {
        case 'location':
          _locationTouched = true;
        case 'item':
          _itemTouched = true;
        case 'description':
          _descriptionTouched = true;
        default:
          _phoneTouched = true;
      }
    });
  }

  void _showCategoryPicker() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoadingCategories) {
      _showCatalogMessage('Kategori kerusakan sedang dimuat…');
      return;
    }
    if (_categoryError != null) {
      _loadCategories(forceRefresh: true);
      return;
    }
    if (_categories.isEmpty) {
      _showCatalogMessage('Kategori kerusakan belum tersedia.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      builder: (sheetContext) => DamageCategorySheet(
        categories: _categories,
        selectedCategory: _selectedCategory,
        onSelected: (category) {
          setState(() {
            _selectedCategory = category;
            _clearFieldErrors(['kategori']);
          });
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    try {
      final categories = await widget.repository.getDamageCategories(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _categories = categories);
    } on ServiceCatalogFailure catch (failure) {
      if (!mounted) return;
      if (failure.type == ServiceCatalogFailureType.unauthorized) {
        await AuthScope.of(context).logout();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _categoryError = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _categoryError = 'Kategori kerusakan belum dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  void _showCatalogMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), margin: const EdgeInsets.all(20)),
      );
  }

  void _showMediaSourcePicker() {
    if (_attachments.length >= _maximumFiles || _isPickingMedia) {
      setState(() {
        _attachmentError = 'Maksimal dua file untuk setiap laporan, ya.';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      builder: (sheetContext) => DamageMediaSourceSheet(
        remainingSlots: _maximumFiles - _attachments.length,
        onSelected: (source) {
          Navigator.pop(sheetContext);
          _pickMedia(source);
        },
      ),
    );
  }

  Future<void> _pickMedia(DamageMediaSource source) async {
    setState(() {
      _isPickingMedia = true;
      _attachmentError = null;
    });

    try {
      final candidates = await _mediaPicker.pick(
        source,
        limit: _maximumFiles - _attachments.length,
      );
      if (!mounted) return;
      _acceptCandidates(candidates);
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _attachmentError = source == DamageMediaSource.gallery
            ? 'Galeri belum dapat dibuka. Coba lagi sebentar, ya.'
            : 'Kamera belum dapat digunakan. Periksa izin kamera lalu coba lagi.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attachmentError =
            'Media belum berhasil ditambahkan. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _recoverLostMedia() async {
    try {
      final recovered = await _mediaPicker.recoverLostMedia();
      if (!mounted || recovered.isEmpty) return;
      _acceptCandidates(recovered);
    } catch (_) {
      // Recovery is best-effort and should never interrupt form entry.
    }
  }

  void _acceptCandidates(List<DamageAttachmentCandidate> candidates) {
    String? validationMessage;
    final accepted = <DamageAttachment>[];

    for (final candidate in candidates) {
      if (_attachments.length + accepted.length >= _maximumFiles) {
        validationMessage = 'Maksimal dua file untuk setiap laporan, ya.';
        break;
      }
      if (candidate.kind == DamageAttachmentKind.unsupported) {
        validationMessage =
            'Format ${candidate.name} belum didukung. Pilih gambar atau video umum.';
        continue;
      }
      final maximumSize = candidate.kind == DamageAttachmentKind.video
          ? _maximumVideoSize
          : _maximumImageSize;
      if (candidate.sizeBytes > maximumSize) {
        validationMessage = candidate.kind == DamageAttachmentKind.video
            ? '${candidate.name} lebih dari 20 MB. Pilih file yang lebih kecil, ya.'
            : '${candidate.name} lebih dari 5 MB. Pilih foto yang lebih kecil, ya.';
        continue;
      }

      accepted.add(
        DamageAttachment(
          id: '${DateTime.now().microsecondsSinceEpoch}-${accepted.length}',
          name: candidate.name,
          sizeBytes: candidate.sizeBytes,
          kind: candidate.kind,
          previewBytes: candidate.previewBytes,
          path: candidate.path,
        ),
      );
    }

    setState(() {
      _attachments.addAll(accepted);
      _attachmentError = validationMessage;
      _clearFieldErrors(['photos']);
    });
  }

  void _removeAttachment(DamageAttachment attachment) {
    setState(() {
      _attachments.removeWhere((item) => item.id == attachment.id);
      _attachmentError = null;
      _clearFieldErrors(['photos']);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
      _submitFieldErrors = const {};
    });
    try {
      final response = await widget.repository.submitDamageReport(
        DamageReportSubmission(
          location: _locationController.text.trim(),
          damageType: _itemController.text.trim(),
          categoryCode: _selectedCategory!.code,
          description: _descriptionController.text.trim(),
          contact: _phoneController.text.trim(),
          attachments: List.unmodifiable(_attachments),
        ),
      );
      if (!mounted) return;
      final successMessage = _successMessage(response);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(successMessage);
        return;
      }
      setState(() {
        _locationController.clear();
        _itemController.clear();
        _descriptionController.clear();
        _phoneController.clear();
        _attachments.clear();
        _selectedCategory = null;
        _attachmentError = null;
        _locationTouched = false;
        _itemTouched = false;
        _descriptionTouched = false;
        _phoneTouched = false;
        _submitFieldErrors = const {};
      });
      _showSubmitMessage(successMessage, success: true);
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

  String? _fieldError(String field) {
    for (final entry in _submitFieldErrors.entries) {
      if (entry.key == field || entry.key.startsWith('$field.')) {
        return entry.value.firstOrNull;
      }
    }
    return null;
  }

  String _successMessage(ServiceSubmitResponse response) {
    final details = [
      if (response.referenceCode != null)
        'Nomor laporan: ${response.referenceCode}',
      if (response.status != null) 'Status: ${response.status}',
    ];
    if (details.isEmpty) return response.message;
    return '${response.message} ${details.join('. ')}.';
  }

  void _clearFieldErrors(Iterable<String> fields) {
    if (_submitFieldErrors.isEmpty) return;
    final next = Map<String, List<String>>.from(_submitFieldErrors);
    for (final field in fields) {
      next.removeWhere((key, _) => key == field || key.startsWith('$field.'));
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
}

class _CatalogLoadNotice extends StatelessWidget {
  const _CatalogLoadNotice({
    required this.loading,
    required this.message,
    this.onRetry,
  });

  final bool loading;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryStrong,
              size: 20,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loading ? 'Memuat kategori kerusakan…' : message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.primaryDeep),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _DamageReportHeader extends StatelessWidget {
  const _DamageReportHeader();

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
                key: const Key('damage_report_back'),
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
                      'Buat laporan baru',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDeep.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Laporan Kerusakan Gedung',
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
                  Icons.home_repair_service_outlined,
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

class _ReporterCard extends StatelessWidget {
  const _ReporterCard({required this.user});

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
          const SizedBox(width: 8),
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

class _DamageIdentityPanel extends StatelessWidget {
  const _DamageIdentityPanel({
    required this.locationController,
    required this.itemController,
    required this.locationFocus,
    required this.itemFocus,
    required this.locationError,
    required this.itemError,
    required this.categoryError,
    required this.category,
    required this.onLocationChanged,
    required this.onItemChanged,
    required this.onChooseCategory,
  });

  final TextEditingController locationController;
  final TextEditingController itemController;
  final FocusNode locationFocus;
  final FocusNode itemFocus;
  final String? locationError;
  final String? itemError;
  final String? categoryError;
  final DamageCategory? category;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onItemChanged;
  final VoidCallback onChooseCategory;

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
          TextField(
            key: const Key('damage_location_field'),
            controller: locationController,
            focusNode: locationFocus,
            onChanged: onLocationChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Lokasi kerusakan',
              hintText: 'Contoh: Gedung 2, Lantai 3',
              prefixIcon: const Icon(Icons.location_on_outlined),
              errorText: locationError,
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const Key('damaged_item_field'),
            controller: itemController,
            focusNode: itemFocus,
            onChanged: onItemChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Nama item yang rusak',
              hintText: 'Contoh: AC Ruang Rapat',
              prefixIcon: const Icon(Icons.handyman_outlined),
              errorText: itemError,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Kategori kerusakan',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 9),
          Material(
            color: category == null
                ? AppColors.primaryPale
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              key: const Key('category_picker'),
              onTap: onChooseCategory,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: category == null
                        ? AppColors.line
                        : AppColors.primaryStrong,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        category == null
                            ? Icons.category_outlined
                            : Icons.check_rounded,
                        color: AppColors.primaryStrong,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.name ?? 'Pilih kategori',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            category == null
                                ? 'Lihat kategori dan contoh item'
                                : category!.examples.isEmpty
                                ? 'Kode ${category!.code}'
                                : category!.examples.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      category == null ? 'Pilih' : 'Ubah',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: AppColors.primaryStrong),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (categoryError != null) ...[
            const SizedBox(height: 7),
            Text(
              categoryError!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.coral),
            ),
          ],
        ],
      ),
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        key: const Key('damage_description_field'),
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        minLines: 4,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: 'Keterangan',
          hintText: 'Contoh: AC tidak mengeluarkan udara dingin dan terdengar suara keras sejak pagi.',
          alignLabelWithHint: true,
          errorText: error,
        ),
      ),
    );
  }
}

class _AttachmentPanel extends StatelessWidget {
  const _AttachmentPanel({
    required this.attachments,
    required this.error,
    required this.isPicking,
    required this.onAdd,
    required this.onRemove,
  });

  final List<DamageAttachment> attachments;
  final String? error;
  final bool isPicking;
  final VoidCallback onAdd;
  final ValueChanged<DamageAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = attachments.length < 2 && !isPicking;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bukti kerusakan',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: attachments.length == 2
                      ? AppColors.mintSoft
                      : AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${attachments.length}/2 file',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: attachments.length == 2
                        ? AppColors.mint
                        : AppColors.primaryDeep,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...attachments.indexed.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.$1 == attachments.length - 1 ? 0 : 10,
                ),
                child: _AttachmentPreview(
                  key: Key('attachment_${entry.$1}'),
                  attachment: entry.$2,
                  index: entry.$1,
                  onRemove: () => onRemove(entry.$2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 13),
          Material(
            color: canAdd ? AppColors.primaryPale : AppColors.canvas,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: const Key('add_attachment'),
              onTap: canAdd ? onAdd : null,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: canAdd ? AppColors.primarySoft : AppColors.line,
                  ),
                ),
                child: isPicking
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryStrong,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Menyiapkan media…',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              canAdd
                                  ? Icons.add_a_photo_outlined
                                  : Icons.check_rounded,
                              color: canAdd
                                  ? AppColors.primaryStrong
                                  : AppColors.mint,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  canAdd
                                      ? 'Tambahkan foto atau video'
                                      : 'Batas lampiran tercapai',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  canAdd
                                      ? 'Foto maks. 5 MB · video maks. 20 MB'
                                      : 'Hapus salah satu untuk mengganti file',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (canAdd)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primaryStrong,
                            ),
                        ],
                      ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: error == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(error),
                    padding: const EdgeInsets.fromLTRB(3, 11, 3, 0),
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

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    super.key,
    required this.attachment,
    required this.index,
    required this.onRemove,
  });

  final DamageAttachment attachment;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isVideo = attachment.kind == DamageAttachmentKind.video;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 62,
              height: 62,
              child: attachment.previewBytes != null && !isVideo
                  ? Image.memory(
                      attachment.previewBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MediaPlaceholder(
                        icon: Icons.image_outlined,
                        color: AppColors.primaryStrong,
                        background: AppColors.primarySoft,
                      ),
                    )
                  : _MediaPlaceholder(
                      icon: isVideo
                          ? Icons.play_arrow_rounded
                          : Icons.image_outlined,
                      color: isVideo
                          ? AppColors.coral
                          : AppColors.primaryStrong,
                      background: isVideo
                          ? AppColors.coralSoft
                          : AppColors.primarySoft,
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${isVideo ? 'Video' : 'Gambar'} · ${_formatFileSize(attachment.sizeBytes)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('remove_attachment_$index'),
            tooltip: 'Hapus lampiran',
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.coralSoft,
              foregroundColor: AppColors.coral,
            ),
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _PhonePanel extends StatelessWidget {
  const _PhonePanel({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        key: const Key('damage_phone_field'),
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
        decoration: InputDecoration(
          labelText: 'Nomor HP',
          hintText: 'Nomor yang dapat dihubungi',
          prefixIcon: const Icon(Icons.phone_outlined),
          errorText: error,
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
                key: const Key('submit_damage_report'),
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
                label: Text(loading ? 'Mengirim…' : 'Kirim Laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
