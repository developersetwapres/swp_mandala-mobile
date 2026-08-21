import '../../damage_report/damage_report_models.dart';

class ServiceSubmitResponse {
  const ServiceSubmitResponse({required this.message});

  final String message;

  factory ServiceSubmitResponse.fromJson(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    final message = json['message'];
    return ServiceSubmitResponse(
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : fallbackMessage,
    );
  }
}

class RoomBookingSubmission {
  const RoomBookingSubmission({
    required this.roomCode,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.participantCount,
    required this.contact,
    required this.meetingType,
    required this.needItSupport,
    required this.itSupportDetail,
    required this.isHybrid,
    required this.hybridDetail,
  });

  final String roomCode;
  final String date;
  final String startTime;
  final String endTime;
  final String purpose;
  final String participantCount;
  final String contact;
  final String meetingType;
  final bool needItSupport;
  final String? itSupportDetail;
  final bool isHybrid;
  final String? hybridDetail;

  Map<String, dynamic> toJson() => {
    'room_code': roomCode,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'purpose': purpose,
    'jumlahPeserta': participantCount,
    'contact': contact,
    'jenisRapat': meetingType,
    'needItSupport': needItSupport,
    'itSupportDetail': itSupportDetail,
    'isHybrid': isHybrid,
    'hybridDetail': hybridDetail,
  };
}

class OfficeSupplySubmissionItem {
  const OfficeSupplySubmissionItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.requested,
  });

  final int? id;
  final String name;
  final String unit;
  final int requested;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'satuan': unit,
    'status': 'requested',
    'requested': requested,
    'approved': 0,
  };
}

class OfficeSupplySubmission {
  const OfficeSupplySubmission({
    required this.items,
    required this.justification,
    required this.contact,
  });

  final List<OfficeSupplySubmissionItem> items;
  final String justification;
  final String contact;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'justification': justification,
    'contact': contact,
  };
}

class DamageReportSubmission {
  const DamageReportSubmission({
    required this.location,
    required this.damageType,
    required this.categoryCode,
    required this.description,
    required this.contact,
    required this.attachments,
  });

  final String location;
  final String damageType;
  final String categoryCode;
  final String description;
  final String contact;
  final List<DamageAttachment> attachments;
}
