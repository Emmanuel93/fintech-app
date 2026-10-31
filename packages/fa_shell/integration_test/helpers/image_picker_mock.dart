import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
// image_picker_platform_interface es una dependencia transitiva de image_picker.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Carpeta servida por el orquestador con los documentos de muestra de la corrida
/// (`ineFrente.jpg`, `ineReverso.jpg`, `selfie.jpg`, `comprobante.jpg`).
///
/// El simulador de iOS comparte la red de la Mac, así que `127.0.0.1` es el host: los documentos
/// se generan allá —con la CURP de esta corrida— y la app los baja al empezar.
const _docsUrl = String.fromEnvironment('RE2E_DOCS_URL');

/// Mock de ImagePickerPlatform para pruebas de integración.
///
/// Con `RE2E_DOCS_URL` entrega **documentos de muestra de verdad**, uno por captura y en el orden
/// en que la app los pide: INE frente, INE reverso, selfie y comprobante de domicilio. En la mesa
/// de cumplimiento una persona los compara contra lo capturado, y eso es lo que el video enseña.
///
/// Sin ella escribe el PNG mínimo de siempre (1×1 px blanco): basta para las pruebas que sólo
/// necesitan que el picker devuelva algo, porque el OCR simulado ignora los bytes.
class FakeImagePickerPlatform extends ImagePickerPlatform {
  FakeImagePickerPlatform._(this._paths);

  final List<String> _paths;
  int _next = 0;

  static const _orden = ['ineFrente', 'ineReverso', 'selfie', 'comprobante'];

  /// Inicializa el mock y lo registra como implementación activa.
  static Future<void> setup() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final paths = <String>[];
    if (_docsUrl.isNotEmpty) {
      for (final doc in _orden) {
        try {
          final r = await http.get(Uri.parse('$_docsUrl/$doc.jpg'));
          if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
            final path = '${Directory.systemTemp.path}/re2e_${doc}_$stamp.jpg';
            await File(path).writeAsBytes(r.bodyBytes);
            paths.add(path);
          }
        } catch (_) {/* sin servidor: se cae al PNG mínimo */}
      }
    }
    if (paths.length != _orden.length) {
      final path = '/tmp/fake_ine_$stamp.png';
      await File(path).writeAsBytes(_minPng());
      paths
        ..clear()
        ..add(path);
    }
    ImagePickerPlatform.instance = FakeImagePickerPlatform._(paths);
  }

  /// El siguiente documento de la secuencia; al terminar vuelve a empezar, como un rollo de fotos.
  XFile _siguiente() => XFile(_paths[_next++ % _paths.length]);

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      _siguiente();

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async =>
      _siguiente();

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
