import 'dart:io';
import 'dart:typed_data';

// image_picker_platform_interface es una dependencia transitiva de image_picker.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Mock de ImagePickerPlatform para pruebas de integración.
///
/// Escribe un PNG mínimo válido (1×1 px blanco) en /tmp y lo devuelve
/// como XFile cada vez que el picker se invoca. Funciona tanto para
/// frente como reverso del INE — el OCR stub ignora los bytes reales.
class FakeImagePickerPlatform extends ImagePickerPlatform {
  FakeImagePickerPlatform._(this._fakePath);

  final String _fakePath;

  /// Inicializa el mock y lo registra como implementación activa.
  static Future<void> setup() async {
    final path = '/tmp/fake_ine_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(_minPng());
    ImagePickerPlatform.instance = FakeImagePickerPlatform._(path);
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      XFile(_fakePath);

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async =>
      XFile(_fakePath);

  // Minimal 1×1 white PNG (valid, 67 bytes)
  static Uint8List _minPng() => Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1×1
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // 8-bit RGB, CRC
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
        0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND
        0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
}
