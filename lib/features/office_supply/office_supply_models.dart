import 'package:flutter/material.dart';

class OfficeSupply {
  const OfficeSupply({
    required this.id,
    required this.name,
    required this.unit,
    required this.icon,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.isOther = false,
  });

  final String id;
  final String name;
  final String? unit;
  final IconData icon;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final bool isOther;

  factory OfficeSupply.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final unit = json['satuan'];
    final categoryId = json['kategori_atk_id'];
    final category = json['kategori_atk'];
    if (id is! num ||
        name is! String ||
        name.trim().isEmpty ||
        unit is! String) {
      throw const FormatException('Invalid office supply data.');
    }

    int? nestedCategoryId;
    String? categoryName;
    if (category is Map<String, dynamic>) {
      final nestedId = category['id'];
      if (nestedId is num) nestedCategoryId = nestedId.toInt();
      final nestedName = category['nama_kategori'];
      if (nestedName is String && nestedName.trim().isNotEmpty) {
        categoryName = nestedName.trim();
      }
    }

    return OfficeSupply(
      id: id.toInt().toString(),
      name: name.trim(),
      unit: unit.trim(),
      icon: Icons.inventory_2_outlined,
      description: categoryName ?? 'Alat tulis kantor',
      categoryId: categoryId is num ? categoryId.toInt() : nestedCategoryId,
      categoryName: categoryName,
    );
  }
}

class RequestedSupply {
  const RequestedSupply({
    required this.id,
    required this.masterId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.isCustom,
  });

  final String id;
  final String? masterId;
  final String name;
  final String unit;
  final int quantity;
  final bool isCustom;

  RequestedSupply copyWith({String? name, String? unit, int? quantity}) {
    return RequestedSupply(
      id: id,
      masterId: masterId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      isCustom: isCustom,
    );
  }
}

class SupplyDraft {
  const SupplyDraft({
    required this.masterId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.isCustom,
  });

  final String? masterId;
  final String name;
  final String unit;
  final int quantity;
  final bool isCustom;
}
