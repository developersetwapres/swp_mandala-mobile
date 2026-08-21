import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiUploadFile {
  const ApiUploadFile({
    required this.field,
    required this.filename,
    this.path,
    this.bytes,
  }) : assert(path != null || bytes != null);

  final String field;
  final String filename;
  final String? path;
  final Uint8List? bytes;

  Future<http.MultipartFile> toMultipartFile() async {
    if (bytes != null) {
      return http.MultipartFile.fromBytes(field, bytes!, filename: filename);
    }
    return http.MultipartFile.fromPath(field, path!, filename: filename);
  }
}
