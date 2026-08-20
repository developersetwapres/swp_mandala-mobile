import 'package:flutter/material.dart';

class OfficeSupply {
  const OfficeSupply({
    required this.id,
    required this.name,
    required this.unit,
    required this.icon,
    required this.description,
    this.isOther = false,
  });

  final String id;
  final String name;
  final String? unit;
  final IconData icon;
  final String description;
  final bool isOther;
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
