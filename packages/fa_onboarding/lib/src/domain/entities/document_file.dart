import 'dart:typed_data';

class DocumentFile {
  const DocumentFile({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
}
