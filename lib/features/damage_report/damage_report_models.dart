import 'dart:typed_data';

class DamageCategory {
  const DamageCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.examples,
  });

  final int id;
  final String code;
  final String name;
  final List<String> examples;

  factory DamageCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final code = json['kode_kerusakan'];
    final name = json['name'];
    if (id is! num ||
        code is! String ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Invalid damage category data.');
    }
    final subcategories = json['sub_kategori'];
    return DamageCategory(
      id: id.toInt(),
      code: code.trim(),
      name: name.trim(),
      examples: subcategories is List
          ? subcategories
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

enum DamageAttachmentKind { image, video, unsupported }

enum DamageMediaSource { cameraPhoto, cameraVideo, gallery }

class DamageAttachmentCandidate {
  const DamageAttachmentCandidate({
    required this.name,
    required this.sizeBytes,
    required this.kind,
    this.previewBytes,
    this.path,
  });

  final String name;
  final int sizeBytes;
  final DamageAttachmentKind kind;
  final Uint8List? previewBytes;
  final String? path;
}

class DamageAttachment {
  const DamageAttachment({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.kind,
    this.previewBytes,
    this.path,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final DamageAttachmentKind kind;
  final Uint8List? previewBytes;
  final String? path;

  Uint8List? get bytes => previewBytes;
}

abstract interface class DamageMediaPicker {
  Future<List<DamageAttachmentCandidate>> pick(
    DamageMediaSource source, {
    required int limit,
  });

  Future<List<DamageAttachmentCandidate>> recoverLostMedia();
}
