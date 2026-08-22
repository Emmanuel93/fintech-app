import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Logotipo tipográfico "Kredius" — Inter 800 con tracking cerrado, igual que
/// el prototipo (`font:800 …/1 'Inter'; letter-spacing:-1.7px` ≈ -0.053·tamaño).
class KrediusWordmark extends StatelessWidget {
  const KrediusWordmark({
    super.key,
    this.fontSize = 28,
    this.color = AppColors.primary,
  });

  /// Variante blanca para fondos azules.
  const KrediusWordmark.onDark({Key? key, double fontSize = 28})
      : this(key: key, fontSize: fontSize, color: AppColors.onPrimary);

  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Kredius',
      // El logotipo no se reescala con el ajuste de accesibilidad del sistema:
      // es marca, no texto de lectura, y debe mantener su proporción con el
      // isotipo que lleva al lado.
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: fontSize * -0.053,
        height: 1.0,
        color: color,
      ),
    );
  }
}
