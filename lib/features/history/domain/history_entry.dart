enum HistoryServiceType { meetingRoom, officeSupply, damage, unknown }

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.typeLabel,
    required this.serviceType,
    required this.isRead,
    required this.code,
    required this.title,
    required this.room,
    required this.info,
    required this.supplyItems,
    required this.subtitle,
    required this.createdAt,
    required this.status,
    required this.user,
    required this.workUnit,
    required this.phone,
    required this.description,
    required this.pictures,
    required this.notes,
    required this.time,
    required this.category,
    required this.needsItSupport,
    required this.isHybrid,
    required this.meetingType,
    required this.itSupportDetail,
    required this.hybridDetail,
  });

  final String id;
  final String typeLabel;
  final HistoryServiceType serviceType;
  final bool isRead;
  final String code;
  final String title;
  final HistoryRoom? room;
  final String? info;
  final List<HistorySupplyItem> supplyItems;
  final String? subtitle;
  final DateTime? createdAt;
  final String status;
  final HistoryUser? user;
  final String? workUnit;
  final String? phone;
  final String? description;
  final List<String> pictures;
  final String? notes;
  final String? time;
  final HistoryDamageCategory? category;
  final bool? needsItSupport;
  final bool? isHybrid;
  final String? meetingType;
  final String? itSupportDetail;
  final String? hybridDetail;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final typeLabel = _text(json['type']) ?? 'Layanan';
    return HistoryEntry(
      id: _text(json['id']) ?? '',
      typeLabel: typeLabel,
      serviceType: _serviceType(typeLabel),
      isRead: _boolean(json['is_read']) ?? false,
      code: _text(json['code']) ?? 'Tanpa kode',
      title: _text(json['title']) ?? 'Pengajuan layanan',
      room: _map(json['ruangans'], HistoryRoom.fromJson),
      info: _text(json['info']),
      supplyItems: _listOfMaps(
        json['daftarkebutuhan'],
        HistorySupplyItem.fromJson,
      ),
      subtitle: _text(json['subtitle']),
      createdAt: _date(json['created_at']),
      status: _text(json['status']) ?? 'unknown',
      user: _map(json['user'], HistoryUser.fromJson),
      workUnit: _text(json['unit_kerja']),
      phone: _text(json['no_hp']),
      description: _text(json['deskripsi']),
      pictures: _stringList(json['picture']),
      notes: _text(json['keterangan']),
      time: _text(json['time']),
      category: _map(json['kategori'], HistoryDamageCategory.fromJson),
      needsItSupport: _boolean(json['is_ti_support']),
      isHybrid: _boolean(json['is_hybrid']),
      meetingType: _text(json['jenis_rapat']),
      itSupportDetail: _text(json['ti_support_detail']),
      hybridDetail: _text(json['hybrid_detail']),
    );
  }

  String get displayTitle {
    if (title.trim().isNotEmpty && title != 'Pengajuan layanan') return title;
    if (serviceType == HistoryServiceType.meetingRoom && room != null) {
      return room!.name ?? 'Pemesanan ruang rapat';
    }
    if (serviceType == HistoryServiceType.officeSupply &&
        supplyItems.isNotEmpty) {
      return '${supplyItems.length} item';
    }
    if (serviceType == HistoryServiceType.damage && category?.name != null) {
      return category!.name!;
    }
    return title;
  }

  String? get compactSummary {
    switch (serviceType) {
      case HistoryServiceType.meetingRoom:
        return _join([subtitle, time, room?.location, info]);
      case HistoryServiceType.officeSupply:
        return info ??
            _join(supplyItems.take(2).map((item) => item.compactLabel));
      case HistoryServiceType.damage:
        return _join([category?.name, info, description]);
      case HistoryServiceType.unknown:
        return info ?? description ?? subtitle;
    }
  }

  String get searchText => [
    code,
    title,
    typeLabel,
    info,
    subtitle,
    description,
    notes,
    room?.name,
    room?.location,
    category?.name,
    category?.damageCode,
    ...supplyItems.map((item) => item.name),
  ].whereType<String>().join(' ').toLowerCase();
}

class HistoryUser {
  const HistoryUser({
    required this.id,
    required this.nip,
    required this.employee,
  });

  final String? id;
  final String? nip;
  final HistoryEmployee? employee;

  factory HistoryUser.fromJson(Map<String, dynamic> json) => HistoryUser(
    id: _text(json['id']),
    nip: _text(json['nip']),
    employee: _map(json['pegawai'], HistoryEmployee.fromJson),
  );
}

class HistoryEmployee {
  const HistoryEmployee({required this.name, required this.bureauName});

  final String? name;
  final String? bureauName;

  factory HistoryEmployee.fromJson(Map<String, dynamic> json) {
    final bureau = json['biro'];
    return HistoryEmployee(
      name: _text(json['name']),
      bureauName: bureau is Map
          ? _text(Map<String, dynamic>.from(bureau)['nama_biro'])
          : null,
    );
  }
}

class HistoryRoom {
  const HistoryRoom({
    required this.id,
    required this.name,
    required this.location,
  });

  final String? id;
  final String? name;
  final String? location;

  factory HistoryRoom.fromJson(Map<String, dynamic> json) => HistoryRoom(
    id: _text(json['id']),
    name: _text(json['nama_ruangan']),
    location: _text(json['lokasi']),
  );
}

class HistorySupplyItem {
  const HistorySupplyItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.status,
    required this.approved,
    required this.requested,
    required this.originId,
    required this.replacedBy,
  });

  final int? id;
  final String name;
  final String? unit;
  final String? status;
  final int? approved;
  final int? requested;
  final String? originId;
  final String? replacedBy;

  factory HistorySupplyItem.fromJson(Map<String, dynamic> json) =>
      HistorySupplyItem(
        id: _integer(json['id']),
        name: _text(json['name']) ?? 'Item ATK',
        unit: _text(json['satuan']),
        status: _text(json['status']),
        approved: _integer(json['approved']),
        requested: _integer(json['requested']),
        originId: _text(json['origin_id']),
        replacedBy: _text(json['replacedBy']),
      );

  String get compactLabel =>
      _join([name, if (requested != null) requested.toString(), unit])!;
}

class HistoryDamageCategory {
  const HistoryDamageCategory({
    required this.id,
    required this.unitCode,
    required this.damageCode,
    required this.section,
    required this.name,
    required this.subcategories,
  });

  final int? id;
  final String? unitCode;
  final String? damageCode;
  final String? section;
  final String? name;
  final List<String> subcategories;

  factory HistoryDamageCategory.fromJson(Map<String, dynamic> json) =>
      HistoryDamageCategory(
        id: _integer(json['id']),
        unitCode: _text(json['kode_unit']),
        damageCode: _text(json['kode_kerusakan']),
        section: _text(json['bagian_kategori']),
        name: _text(json['name']),
        subcategories: _stringList(json['sub_kategori']),
      );
}

HistoryServiceType _serviceType(String value) {
  switch (value.trim().toLowerCase()) {
    case 'atk':
      return HistoryServiceType.officeSupply;
    case 'ruangan rapat':
      return HistoryServiceType.meetingRoom;
    case 'kerusakan':
      return HistoryServiceType.damage;
    default:
      return HistoryServiceType.unknown;
  }
}

T? _map<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value is! Map) return null;
  return parser(Map<String, dynamic>.from(value));
}

List<T> _listOfMaps<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return const [];
  return List.unmodifiable(
    value.whereType<Map>().map(
      (item) => parser(Map<String, dynamic>.from(item)),
    ),
  );
}

List<String> _stringList(Object? value) {
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  if (value is! List) return const [];
  return List.unmodifiable(
    value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty),
  );
}

String? _text(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final result = value.trim();
    return result.isEmpty ? null : result;
  }
  if (value is num) return value.toString();
  return null;
}

int? _integer(Object? value) {
  if (value is num) return value.toInt();
  return value is String ? int.tryParse(value) : null;
}

bool? _boolean(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    if (value == '1' || value.toLowerCase() == 'true') return true;
    if (value == '0' || value.toLowerCase() == 'false') return false;
  }
  return null;
}

DateTime? _date(Object? value) {
  final raw = _text(value);
  return raw == null ? null : DateTime.tryParse(raw);
}

String? _join(Iterable<String?> values) {
  final clean = values
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return clean.isEmpty ? null : clean.join(' · ');
}
