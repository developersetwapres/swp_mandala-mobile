class MeetingRoom {
  const MeetingRoom({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.capacity,
    required this.maximumCapacityLabel,
    required this.maximumCapacity,
    required this.isAvailable,
    required this.islandName,
    required this.philosophy,
    required this.bookedSlots,
    required this.bookedByBureaus,
    required this.facilities,
    this.imageUrl,
    this.descriptionImageUrl,
  });

  final String id;
  final String name;
  final String code;
  final String location;
  final String capacity;
  final String maximumCapacityLabel;
  final int maximumCapacity;
  final bool isAvailable;
  final String islandName;
  final String philosophy;
  final List<String> bookedSlots;
  final List<String> bookedByBureaus;
  final List<String> facilities;
  final String? imageUrl;
  final String? descriptionImageUrl;

  String get bookedInformation {
    final slots = bookedSlots.isEmpty
        ? 'jadwal terpilih'
        : bookedSlots.join(', ');
    final bureaus = bookedByBureaus.isEmpty
        ? 'unit kerja lain'
        : bookedByBureaus.join(', ');
    return 'Ruangan sedang digunakan pada $slots oleh $bureaus.';
  }

  factory MeetingRoom.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json['id']);
    final name = _requiredString(json['nama_ruangan']);
    final location = _requiredString(json['location']);
    final capacity = _requiredString(json['kapasitas']);
    final maximumCapacityLabel = _requiredString(json['kapasitas_max']);
    final status = _requiredString(json['status']).toLowerCase();

    return MeetingRoom(
      id: id,
      name: name,
      code: _optionalString(json['kode_ruangan']) ?? id,
      location: _optionalString(json['lokasi']) ?? 'Lokasi belum tersedia',
      capacity: capacity,
      maximumCapacityLabel: maximumCapacityLabel,
      maximumCapacity: _capacityTotal(maximumCapacityLabel),
      isAvailable: status == 'available',
      islandName: _optionalString(json['lokasi_desc']) ?? name,
      philosophy: _optionalString(json['deskripsi']) ?? '',
      bookedSlots: _stringList(json['bookedSlots']),
      bookedByBureaus: _stringList(json['bookedByBiro']),
      facilities: _stringList(json['facilities']),
      imageUrl: _optionalString(json['image']),
      descriptionImageUrl: _optionalString(json['image_desc']),
    );
  }

  static int _capacityTotal(String value) {
    final numbers = RegExp(r'\d+')
        .allMatches(value)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    if (numbers.isEmpty) return 1;
    return numbers.fold(0, (total, number) => total + number);
  }

  static String _requiredString(dynamic value) {
    final parsed = _optionalString(value);
    if (parsed == null) throw const FormatException('Invalid room data.');
    return parsed;
  }

  static String? _optionalString(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

enum MeetingType { internal, external }

extension MeetingTypeLabel on MeetingType {
  String get label => switch (this) {
    MeetingType.internal => 'Rapat Internal',
    MeetingType.external => 'Rapat External',
  };
}
