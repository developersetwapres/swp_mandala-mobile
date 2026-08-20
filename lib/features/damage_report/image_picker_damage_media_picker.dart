import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'damage_report_models.dart';

class ImagePickerDamageMediaPicker implements DamageMediaPicker {
  ImagePickerDamageMediaPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const int _previewReadLimit = 20 * 1024 * 1024;

  final ImagePicker _picker;

  @override
  Future<List<DamageAttachmentCandidate>> pick(
    DamageMediaSource source, {
    required int limit,
  }) async {
    final files = switch (source) {
      DamageMediaSource.cameraPhoto => [
        ?await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 88,
          maxWidth: 2000,
          requestFullMetadata: false,
        ),
      ],
      DamageMediaSource.cameraVideo => [
        ?await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 5),
        ),
      ],
      DamageMediaSource.gallery => await _picker.pickMultipleMedia(
        limit: limit,
        imageQuality: 88,
        maxWidth: 2000,
        requestFullMetadata: false,
      ),
    };

    return Future.wait(files.map(_toCandidate));
  }

  @override
  Future<List<DamageAttachmentCandidate>> recoverLostMedia() async {
    final response = await _picker.retrieveLostData();
    final files = response.files;
    if (files == null || files.isEmpty) return const [];
    return Future.wait(files.map(_toCandidate));
  }

  Future<DamageAttachmentCandidate> _toCandidate(XFile file) async {
    final size = await file.length();
    final kind = _kindFromName(file.name);
    Uint8List? previewBytes;

    if (kind == DamageAttachmentKind.image && size <= _previewReadLimit) {
      previewBytes = await file.readAsBytes();
    }

    return DamageAttachmentCandidate(
      name: file.name,
      sizeBytes: size,
      kind: kind,
      previewBytes: previewBytes,
    );
  }

  DamageAttachmentKind _kindFromName(String name) {
    final extension = name.split('.').last.toLowerCase();
    const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
    const videoExtensions = {'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'};

    if (imageExtensions.contains(extension)) return DamageAttachmentKind.image;
    if (videoExtensions.contains(extension)) return DamageAttachmentKind.video;
    return DamageAttachmentKind.unsupported;
  }
}
