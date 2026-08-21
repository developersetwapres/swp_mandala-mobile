import '../../damage_report/damage_report_models.dart';

class ServiceSubmitResponse {
  const ServiceSubmitResponse({
    required this.message,
    this.referenceCode,
    this.status,
    this.picture = const [],
    this.daftarKebutuhan = const [],
    this.tanggalPenggunaan,
    this.jamMulai,
    this.jamSelesai,
  });

  final String message;
  final String? referenceCode;
  final String? status;
  final List<Object?> picture;
  final List<Object?> daftarKebutuhan;
  final String? tanggalPenggunaan;
  final String? jamMulai;
  final String? jamSelesai;

  factory ServiceSubmitResponse.fromJson(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    final message = json['message'];
    final data = json['data'];
    final responseData = data is Map<String, dynamic> ? data : const {};
    final reportCode = responseData['kode_pelaporan'];
    final bookingCode = responseData['kode_booking'];
    return ServiceSubmitResponse(
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : fallbackMessage,
      referenceCode: reportCode is String
          ? reportCode
          : bookingCode is String
          ? bookingCode
          : null,
      status: responseData['status'] is String
          ? responseData['status'] as String
          : null,
      picture: responseData['picture'] is List
          ? List<Object?>.unmodifiable(responseData['picture'] as List)
          : const [],
      daftarKebutuhan: responseData['daftar_kebutuhan'] is List
          ? List<Object?>.unmodifiable(responseData['daftar_kebutuhan'] as List)
          : const [],
      tanggalPenggunaan: responseData['tanggal_penggunaan'] is String
          ? responseData['tanggal_penggunaan'] as String
          : null,
      jamMulai: responseData['jam_mulai'] is String
          ? responseData['jam_mulai'] as String
          : null,
      jamSelesai: responseData['jam_selesai'] is String
          ? responseData['jam_selesai'] as String
          : null,
    );
  }
}

class RoomBookingSubmission {
  const RoomBookingSubmission({
    required this.roomCode,
    this.roomName,
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
  final String? roomName;
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
    'room_name': roomName,
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
    required this.isCustom,
  });

  final int? id;
  final String name;
  final String unit;
  final int requested;
  final bool isCustom;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'satuan': unit,
    'status': isCustom ? 'custom' : 'normal',
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
