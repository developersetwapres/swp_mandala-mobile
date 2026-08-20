import 'dart:typed_data';

class DamageCategory {
  const DamageCategory({
    required this.name,
    required this.examples,
    required this.description,
  });

  final String name;
  final List<String> examples;
  final String description;
}

enum DamageAttachmentKind { image, video, unsupported }

enum DamageMediaSource { cameraPhoto, cameraVideo, gallery }

class DamageAttachmentCandidate {
  const DamageAttachmentCandidate({
    required this.name,
    required this.sizeBytes,
    required this.kind,
    this.previewBytes,
  });

  final String name;
  final int sizeBytes;
  final DamageAttachmentKind kind;
  final Uint8List? previewBytes;
}

class DamageAttachment {
  const DamageAttachment({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.kind,
    this.previewBytes,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final DamageAttachmentKind kind;
  final Uint8List? previewBytes;
}

abstract interface class DamageMediaPicker {
  Future<List<DamageAttachmentCandidate>> pick(
    DamageMediaSource source, {
    required int limit,
  });

  Future<List<DamageAttachmentCandidate>> recoverLostMedia();
}
