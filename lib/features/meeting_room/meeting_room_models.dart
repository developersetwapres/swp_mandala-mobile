class MeetingRoom {
  const MeetingRoom({
    required this.name,
    required this.location,
    required this.capacity,
    required this.maximumCapacity,
    required this.isAvailable,
    required this.islandName,
    required this.philosophy,
    this.bookedTime,
    this.bookedBy,
  });

  final String name;
  final String location;
  final int capacity;
  final int maximumCapacity;
  final bool isAvailable;
  final String islandName;
  final String philosophy;
  final String? bookedTime;
  final String? bookedBy;
}

enum MeetingType { internal, external }

extension MeetingTypeLabel on MeetingType {
  String get label => switch (this) {
    MeetingType.internal => 'Rapat Internal',
    MeetingType.external => 'Rapat External',
  };
}
