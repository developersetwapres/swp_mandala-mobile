import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/auth_scope.dart';
import '../service_catalog/domain/service_catalog_failure.dart';
import '../service_catalog/domain/service_catalog_repository.dart';
import '../service_catalog/domain/service_submission_failure.dart';
import '../service_catalog/domain/service_submission_models.dart';
import 'office_supply_models.dart';
import 'office_supply_selector_sheet.dart';
import 'supply_item_editor_sheet.dart';

class OfficeSupplyRequestPage extends StatefulWidget {
  const OfficeSupplyRequestPage({
    required this.user,
    required this.repository,
    super.key,
  });

  final AppUser user;
  final ServiceCatalogRepository repository;

  @override
  State<OfficeSupplyRequestPage> createState() =>
      _OfficeSupplyRequestPageState();
}

class _OfficeSupplyRequestPageState extends State<OfficeSupplyRequestPage> {
  static const OfficeSupply _otherSupply = OfficeSupply(
    id: 'other',
    name: 'Lain-Lain',
    unit: null,
    icon: Icons.add_box_outlined,
    description: 'Tambahkan barang yang belum ada di daftar.',
    isOther: true,
  );

  final _noteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  final List<RequestedSupply> _requestedItems = [];

  bool _phoneTouched = false;
  List<OfficeSupply> _masterSupplies = const [_otherSupply];
  bool _isLoadingSupplies = true;
  String? _supplyError;
  bool _isSubmitting = false;
  Map<String, List<String>> _submitFieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus && mounted) {
        setState(() => _phoneTouched = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupplies());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 && _phoneController.text.length <= 15;
  }

  bool get _isJustificationValid {
    final value = _noteController.text.trim();
    return value.isNotEmpty && value.length <= 255;
  }

  bool get _canSubmit =>
      _requestedItems.isNotEmpty && _isJustificationValid && _isPhoneValid;

  String get _submitHint {
    if (_requestedItems.isEmpty) return 'Tambahkan minimal satu item ATK';
    if (!_isJustificationValid) return 'Lengkapi keterangan kebutuhan';
    if (!_isPhoneValid) return 'Lengkapi nomor HP yang dapat dihubungi';
    return '${_requestedItems.length} item siap diajukan';
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
            const _OfficeSupplyHeader(),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('office_supply_scroll'),
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
                            title: 'Informasi pemohon',
                            subtitle: 'Permintaan akan diajukan atas namamu.',
                          ),
                          const SizedBox(height: 14),
                          _ApplicantCard(user: widget.user),
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '02',
                            title: 'Susun permintaan',
                            subtitle:
                                'Tambahkan satu atau beberapa kebutuhan ATK.',
                          ),
                          const SizedBox(height: 14),
                          _SupplyBasket(
                            items: _requestedItems,
                            onAdd: _openSupplySelector,
                            onEdit: _editItem,
                            onRemove: _removeItem,
                            onDecrease: (item) => _changeQuantity(item, -1),
                            onIncrease: (item) => _changeQuantity(item, 1),
                          ),
                          if (_fieldError('items') != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _fieldError('items')!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.coral),
                            ),
                          ],
                          if (_isLoadingSupplies ||
                              _supplyError != null ||
                              (!_isLoadingSupplies &&
                                  _masterSupplies.length == 1)) ...[
                            const SizedBox(height: 12),
                            _SupplyCatalogNotice(
                              loading: _isLoadingSupplies,
                              message:
                                  _supplyError ??
                                  (_masterSupplies.length == 1
                                      ? 'Data ATK belum tersedia. Opsi Lain-Lain tetap dapat digunakan.'
                                      : ''),
                              onRetry: _supplyError == null
                                  ? null
                                  : () => _loadSupplies(forceRefresh: true),
                            ),
                          ],
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '03',
                            title: 'Keterangan',
                            subtitle:
                                'Tambahkan catatan bila ada kebutuhan khusus.',
                          ),
                          const SizedBox(height: 14),
                          _NotePanel(
                            controller: _noteController,
                            error: _fieldError('justification'),
                            onChanged: (_) => setState(
                              () => _clearFieldErrors(['justification']),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _SectionIntro(
                            number: '04',
                            title: 'Kontak pemohon',
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
          hint: _isSubmitting ? 'Mengirim permintaan…' : _submitHint,
          onSubmit: _submit,
        ),
      ),
    );
  }

  Future<void> _openSupplySelector() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoadingSupplies) {
      _showMessage('Daftar ATK sedang dimuat…');
      return;
    }
    if (_supplyError != null) {
      _loadSupplies(forceRefresh: true);
      return;
    }
    final selectedIds = _requestedItems
        .map((item) => item.masterId)
        .whereType<String>()
        .toSet();

    final supply = await showModalBottomSheet<OfficeSupply>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      builder: (context) => OfficeSupplySelectorSheet(
        supplies: _masterSupplies,
        selectedMasterIds: selectedIds,
      ),
    );
    if (supply == null || !mounted) return;

    if (!supply.isOther) {
      final existing = _requestedItems
          .where((item) => item.masterId == supply.id)
          .firstOrNull;
      if (existing != null) {
        _showMessage('${supply.name} sudah ada. Silakan perbarui jumlahnya.');
        await _openItemEditor(supply: supply, existingItem: existing);
        return;
      }
    }

    await _openItemEditor(supply: supply);
  }

  Future<void> _loadSupplies({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingSupplies = true;
      _supplyError = null;
    });
    try {
      final supplies = await widget.repository.getAvailableOfficeSupplies(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _masterSupplies = [_otherSupply, ...supplies]);
    } on ServiceCatalogFailure catch (failure) {
      if (!mounted) return;
      if (failure.type == ServiceCatalogFailureType.unauthorized) {
        await AuthScope.of(context).logout();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _supplyError = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _supplyError = 'Daftar ATK belum dapat dimuat.');
      }
    } finally {
      if (mounted) setState(() => _isLoadingSupplies = false);
    }
  }

  Future<void> _editItem(RequestedSupply item) async {
    final supply = item.masterId == null
        ? null
        : _masterSupplies
              .where((supply) => supply.id == item.masterId)
              .firstOrNull;
    await _openItemEditor(supply: supply, existingItem: item);
  }

  Future<void> _openItemEditor({
    OfficeSupply? supply,
    RequestedSupply? existingItem,
  }) async {
    final draft = await showModalBottomSheet<SupplyDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.34),
      builder: (context) =>
          SupplyItemEditorSheet(supply: supply, existingItem: existingItem),
    );
    if (draft == null || !mounted) return;

    if (existingItem == null) {
      _addDraft(draft);
    } else {
      _updateItem(existingItem, draft);
    }
  }

  void _addDraft(SupplyDraft draft) {
    _clearFieldErrors(['items']);
    if (draft.masterId != null) {
      final existingIndex = _requestedItems.indexWhere(
        (item) => item.masterId == draft.masterId,
      );
      if (existingIndex != -1) {
        final current = _requestedItems[existingIndex];
        setState(() {
          _requestedItems[existingIndex] = current.copyWith(
            quantity: draft.quantity,
          );
        });
        _showMessage('Jumlah ${current.name} diperbarui.');
        return;
      }
    }

    final customDuplicateIndex = draft.isCustom
        ? _findCustomDuplicate(draft.name)
        : -1;
    if (customDuplicateIndex != -1) {
      final existing = _requestedItems[customDuplicateIndex];
      if (_normalized(existing.unit) != _normalized(draft.unit)) {
        _showMessage(
          '${existing.name} sudah ada dengan satuan ${existing.unit}. Edit item tersebut, ya.',
        );
        return;
      }
      setState(() {
        _requestedItems[customDuplicateIndex] = existing.copyWith(
          quantity: (existing.quantity + draft.quantity).clamp(1, 999),
        );
      });
      _showMessage(
        'Jumlah ${existing.name} digabungkan ke item yang sudah ada.',
      );
      return;
    }

    setState(() {
      _requestedItems.add(
        RequestedSupply(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          masterId: draft.masterId,
          name: draft.name,
          unit: draft.unit,
          quantity: draft.quantity,
          isCustom: draft.isCustom,
        ),
      );
    });
    _showMessage('${draft.name} ditambahkan ke permintaan.');
  }

  void _updateItem(RequestedSupply original, SupplyDraft draft) {
    _clearFieldErrors(['items']);
    final originalIndex = _requestedItems.indexWhere(
      (item) => item.id == original.id,
    );
    if (originalIndex == -1) return;

    if (draft.isCustom) {
      final duplicateIndex = _findCustomDuplicate(
        draft.name,
        excludingId: original.id,
      );
      if (duplicateIndex != -1) {
        final duplicate = _requestedItems[duplicateIndex];
        if (_normalized(duplicate.unit) != _normalized(draft.unit)) {
          _showMessage(
            '${duplicate.name} sudah ada dengan satuan ${duplicate.unit}.',
          );
          return;
        }
        setState(() {
          _requestedItems[duplicateIndex] = duplicate.copyWith(
            quantity: (duplicate.quantity + draft.quantity).clamp(1, 999),
          );
          _requestedItems.removeWhere((item) => item.id == original.id);
        });
        _showMessage('Item serupa digabungkan agar tidak duplikat.');
        return;
      }
    }

    setState(() {
      _requestedItems[originalIndex] = original.copyWith(
        name: draft.name,
        unit: draft.unit,
        quantity: draft.quantity,
      );
    });
  }

  int _findCustomDuplicate(String name, {String? excludingId}) {
    return _requestedItems.indexWhere(
      (item) =>
          item.isCustom &&
          item.id != excludingId &&
          _normalized(item.name) == _normalized(name),
    );
  }

  String _normalized(String value) => value.trim().toLowerCase();

  void _changeQuantity(RequestedSupply item, int delta) {
    final index = _requestedItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    final next = (item.quantity + delta).clamp(1, 999);
    setState(() {
      _requestedItems[index] = item.copyWith(quantity: next);
    });
  }

  void _removeItem(RequestedSupply item) {
    final index = _requestedItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _requestedItems.removeAt(index));
    _clearFieldErrors(['items']);

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.name} dihapus dari permintaan.'),
          margin: const EdgeInsets.all(20),
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: AppColors.primary,
            onPressed: () {
              if (!mounted ||
                  _requestedItems.any((entry) => entry.id == item.id)) {
                return;
              }
              setState(() {
                _requestedItems.insert(
                  index.clamp(0, _requestedItems.length),
                  item,
                );
              });
            },
          ),
        ),
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
      final response = await widget.repository.submitOfficeSupplyRequest(
        OfficeSupplySubmission(
          items: _requestedItems
              .map(
                (item) => OfficeSupplySubmissionItem(
                  id: item.isCustom ? null : int.tryParse(item.masterId ?? ''),
                  name: item.name,
                  unit: item.unit,
                  requested: item.quantity,
                ),
              )
              .toList(growable: false),
          justification: _noteController.text.trim(),
          contact: _phoneController.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _requestedItems.clear();
        _noteController.clear();
        _phoneController.clear();
        _phoneTouched = false;
        _submitFieldErrors = const {};
      });
      _showSubmitMessage(response.message, success: true);
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

  String? _fieldError(String field) => _submitFieldErrors[field]?.firstOrNull;

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

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _SupplyCatalogNotice extends StatelessWidget {
  const _SupplyCatalogNotice({
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
              loading ? 'Memuat daftar ATK…' : message,
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

class _OfficeSupplyHeader extends StatelessWidget {
  const _OfficeSupplyHeader();

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
                key: const Key('office_supply_back'),
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
                      'Buat permintaan baru',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDeep.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Permintaan Alat Tulis Kantor',
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
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 25,
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

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.user});

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

class _SupplyBasket extends StatelessWidget {
  const _SupplyBasket({
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });

  final List<RequestedSupply> items;
  final VoidCallback onAdd;
  final ValueChanged<RequestedSupply> onEdit;
  final ValueChanged<RequestedSupply> onRemove;
  final ValueChanged<RequestedSupply> onDecrease;
  final ValueChanged<RequestedSupply> onIncrease;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daftar permintaan',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: items.isEmpty
                      ? AppColors.primaryPale
                      : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} item',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: items.isEmpty
                        ? AppColors.primaryDeep
                        : AppColors.mint,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            child: items.isEmpty
                ? const _EmptyBasket(key: ValueKey('empty_basket'))
                : Column(
                    key: const ValueKey('filled_basket'),
                    children: items.indexed
                        .map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.$1 == items.length - 1 ? 0 : 10,
                            ),
                            child: _RequestedItemCard(
                              item: entry.$2,
                              index: entry.$1,
                              onEdit: () => onEdit(entry.$2),
                              onRemove: () => onRemove(entry.$2),
                              onDecrease: () => onDecrease(entry.$2),
                              onIncrease: () => onIncrease(entry.$2),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('add_supply_item'),
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryStrong,
                side: const BorderSide(color: AppColors.primarySoft),
                backgroundColor: AppColors.primaryPale,
                minimumSize: const Size(48, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(items.isEmpty ? 'Pilih ATK' : 'Tambah Item'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: AppColors.primaryStrong,
              size: 24,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Belum ada item ATK',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih barang lalu tentukan jumlahnya.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RequestedItemCard extends StatelessWidget {
  const _RequestedItemCard({
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });

  final RequestedSupply item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('requested_item_$index'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isCustom
                      ? AppColors.lavenderSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.isCustom
                      ? Icons.add_box_outlined
                      : Icons.inventory_2_outlined,
                  color: item.isCustom
                      ? AppColors.lavender
                      : AppColors.primaryStrong,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.isCustom ? 'Item Lain-Lain' : 'Master ATK',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('edit_requested_item_$index'),
                tooltip: 'Edit item',
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primaryStrong,
                  backgroundColor: AppColors.primarySoft,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              const SizedBox(width: 3),
              IconButton(
                key: Key('remove_requested_item_$index'),
                tooltip: 'Hapus item',
                onPressed: onRemove,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  backgroundColor: AppColors.coralSoft,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconButton(
                  key: Key('decrease_requested_item_$index'),
                  tooltip: 'Kurangi jumlah',
                  onPressed: item.quantity > 1 ? onDecrease : null,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      '${item.quantity} ${item.unit}',
                      key: ValueKey('${item.quantity}-${item.unit}'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.primaryDeep),
                    ),
                  ),
                ),
                IconButton(
                  key: Key('increase_requested_item_$index'),
                  tooltip: 'Tambah jumlah',
                  onPressed: item.quantity < 999 ? onIncrease : null,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    color: AppColors.primaryStrong,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotePanel extends StatelessWidget {
  const _NotePanel({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
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
        key: const Key('supply_note_field'),
        controller: controller,
        onChanged: onChanged,
        minLines: 3,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: 'Keterangan',
          hintText: 'Contoh: digunakan untuk administrasi bulanan',
          alignLabelWithHint: true,
          errorText: error,
        ),
      ),
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
        key: const Key('supply_phone_field'),
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
                key: const Key('submit_supply_request'),
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
                label: Text(loading ? 'Mengirim…' : 'Ajukan Permintaan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
