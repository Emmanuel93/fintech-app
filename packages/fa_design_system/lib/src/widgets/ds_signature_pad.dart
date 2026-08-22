import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Controlador del pad: guarda los trazos y sabe exportarlos a PNG.
///
/// Se maneja desde fuera para que la pantalla pueda habilitar su CTA en cuanto
/// haya algo dibujado y pedir la imagen al firmar.
class DsSignatureController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  List<List<Offset>> get strokes => List.unmodifiable(_strokes);
  bool get isEmpty => _strokes.every((s) => s.length < 2);
  bool get isNotEmpty => !isEmpty;

  void startStroke(Offset p) {
    _strokes.add([p]);
    notifyListeners();
  }

  void appendPoint(Offset p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(p);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// Lo llama el pad al medirse; se necesita para exportar con el mismo encuadre.
  void setSize(Size size) => _size = size;

  /// PNG con fondo transparente, listo para estamparse sobre el PDF.
  ///
  /// Se exporta a 3× para que la firma no salga pixelada al imprimirse: en un
  /// contrato el trazo se ve al tamaño de una firma real, no de un widget.
  Future<Uint8List?> toPngBytes({double pixelRatio = 3}) async {
    if (isEmpty || _size == Size.zero) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    _paintStrokes(canvas, _strokes, AppColors.onSurface);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (_size.width * pixelRatio).ceil(),
      (_size.height * pixelRatio).ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  static void _paintStrokes(
      Canvas canvas, List<List<Offset>> strokes, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        // Curva entre puntos medios: suaviza el trazo del dedo, que llega a
        // saltos, sin que se vea poligonal.
        final prev = stroke[i - 1];
        final current = stroke[i];
        final mid = Offset((prev.dx + current.dx) / 2, (prev.dy + current.dy) / 2);
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      canvas.drawPath(path, paint);
    }
  }
}

/// Pad de firma autógrafa.
///
/// Recuadro punteado con la línea de firma, como en papel. Lo que se dibuja
/// aquí se estampa después sobre el PDF del contrato: es la firma que queda en
/// el documento, no un adorno.
class DsSignaturePad extends StatelessWidget {
  const DsSignaturePad({
    super.key,
    required this.controller,
    this.height = 180,
    this.hint = 'Firma con tu dedo dentro del recuadro',
  });

  final DsSignatureController controller;
  final double height;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, ds.h(height));
            controller.setSize(size);

            return Semantics(
              label: 'Recuadro de firma. $hint',
              child: GestureDetector(
                onPanStart: (d) => controller.startStroke(d.localPosition),
                onPanUpdate: (d) => controller.appendPoint(d.localPosition),
                child: Container(
                  height: size.height,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(ds.r(AppRadii.cardSmall)),
                    border: Border.all(
                      color: controller.isNotEmpty
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(ds.r(AppRadii.cardSmall)),
                    child: CustomPaint(
                      painter: _PadPainter(
                        strokes: controller.strokes,
                        baseline: size.height * 0.78,
                      ),
                      child: controller.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: ds.h(26)),
                                child: Text(
                                  hint,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body(
                                    fontSize: ds.sp(12.5),
                                    color: AppColors.disabled,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter({required this.strokes, required this.baseline});

  final List<List<Offset>> strokes;
  final double baseline;

  @override
  void paint(Canvas canvas, Size size) {
    // Línea de firma punteada, como en un documento impreso.
    final guide = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    const dash = 6.0, gap = 5.0;
    for (var x = 24.0; x < size.width - 24; x += dash + gap) {
      canvas.drawLine(
          Offset(x, baseline), Offset(x + dash, baseline), guide);
    }

    DsSignatureController._paintStrokes(canvas, strokes, AppColors.onSurface);
  }

  @override
  bool shouldRepaint(_PadPainter old) =>
      old.strokes != strokes || old.baseline != baseline;
}
