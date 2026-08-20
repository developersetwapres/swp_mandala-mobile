import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'office_supply_models.dart';

class SupplyItemEditorSheet extends StatefulWidget {
  const SupplyItemEditorSheet({super.key, this.supply, this.existingItem})
    : assert(supply != null || existingItem != null);

  final OfficeSupply? supply;
  final RequestedSupply? existingItem;

  @override
  State<SupplyItemEditorSheet> createState() => _SupplyItemEditorSheetState();
}

class _SupplyItemEditorSheetState extends State<SupplyItemEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  bool _showErrors = false;

  bool get _isCustom =>
      widget.supply?.isOther ?? widget.existingItem?.isCustom ?? true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? (_isCustom ? '' : widget.supply?.name),
    );
    _quantityController = TextEditingController(
      text: '${widget.existingItem?.quantity ?? 1}',
    );
    _unitController = TextEditingController(
      text: widget.existingItem?.unit ?? widget.supply?.unit ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  int? get _quantity => int.tryParse(_quantityController.text);

  String? get _nameError {
    if (!_showErrors || !_isCustom || _nameController.text.trim().isNotEmpty) {
      return null;
    }
    return 'Nama barang perlu diisi.';
  }

  String? get _quantityError {
    if (!_showErrors) return null;
    if (_quantity == null || _quantity! < 1) {
      return 'Jumlah minimal 1.';
    }
    return null;
  }

  String? get _unitError {
    if (!_showErrors || !_isCustom || _unitController.text.trim().isNotEmpty) {
      return null;
    }
    return 'Satuan barang perlu diisi.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing = widget.existingItem != null;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEditing
                      ? 'Edit item permintaan'
                      : 'Tambahkan ke permintaan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  _isCustom
                      ? 'Lengkapi nama barang, jumlah, dan satuannya.'
                      : 'Satuan mengikuti master ATK secara otomatis.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                if (_isCustom) ...[
                  TextField(
                    key: const Key('custom_supply_name'),
                    controller: _nameController,
                    autofocus: !isEditing,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nama barang',
                      hintText: 'Contoh: Label Printer',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 13),
                ] else
                  _SelectedSupplyIdentity(supply: widget.supply!),
                if (!_isCustom) const SizedBox(height: 16),
                Text('Jumlah', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 9),
                _QuantityControl(
                  controller: _quantityController,
                  error: _quantityError,
                  onDecrease: () => _changeQuantity(-1),
                  onIncrease: () => _changeQuantity(1),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (_isCustom)
                  TextField(
                    key: const Key('custom_supply_unit'),
                    controller: _unitController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Satuan',
                      hintText: 'Contoh: Roll, Pcs, Box',
                      prefixIcon: const Icon(Icons.straighten_rounded),
                      errorText: _unitError,
                    ),
                  )
                else
                  _ReadOnlyUnit(unit: widget.supply!.unit!),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('save_supply_item'),
                    onPressed: _save,
                    icon: Icon(
                      isEditing ? Icons.check_rounded : Icons.add_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isEditing ? 'Simpan Perubahan' : 'Tambah ke Permintaan',
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

  void _changeQuantity(int delta) {
    final next = ((_quantity ?? 1) + delta).clamp(1, 999);
    _quantityController.text = '$next';
    _quantityController.selection = TextSelection.collapsed(
      offset: _quantityController.text.length,
    );
    setState(() {});
  }

  void _save() {
    setState(() => _showErrors = true);
    if (_nameError != null || _quantityError != null || _unitError != null) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(
      context,
      SupplyDraft(
        masterId: _isCustom ? null : widget.supply!.id,
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        quantity: _quantity!,
        isCustom: _isCustom,
      ),
    );
  }
}

class _SelectedSupplyIdentity extends StatelessWidget {
  const _SelectedSupplyIdentity({required this.supply});

  final OfficeSupply supply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(supply.icon, color: AppColors.primaryStrong, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supply.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  supply.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primaryStrong,
            size: 21,
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.controller,
    required this.error,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filled(
          key: const Key('quantity_decrease'),
          tooltip: 'Kurangi jumlah',
          onPressed: onDecrease,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primaryStrong,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.remove_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            key: const Key('supply_quantity_field'),
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '1',
              errorText: error,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          key: const Key('quantity_increase'),
          tooltip: 'Tambah jumlah',
          onPressed: onIncrease,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primaryStrong,
            foregroundColor: Colors.white,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _ReadOnlyUnit extends StatelessWidget {
  const _ReadOnlyUnit({required this.unit});

  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_rounded, color: AppColors.mint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satuan otomatis',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(unit, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.mint,
            size: 18,
          ),
        ],
      ),
    );
  }
}
