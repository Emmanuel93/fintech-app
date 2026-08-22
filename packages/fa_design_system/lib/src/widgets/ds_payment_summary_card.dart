import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Tarjeta de resumen de pago — gradiente azul Kredius, un valor destacado
/// arriba (monto aprobado o pago mensual, según el caller) y filas de
/// detalle abajo. A propósito no tiene ningún parámetro de tasa/CAT: el
/// criterio de este journey es mostrar solo lo que el usuario paga —
/// "intereses incluidos" se destaca en menta, igual que el prototipo.
class DsPaymentSummaryCard extends StatelessWidget {
  const DsPaymentSummaryCard({
    super.key,
    required this.headlineLabel,
    required this.headlineValue,
    this.subLabel,
    this.emphasizedRow,
    this.interestRow,
    this.rows = const [],
    this.footnote,
  });

  /// Texto de entrada en frase (ej. "Pagas cada mes"), no se transforma a
  /// mayúsculas — el prototipo la usa en tono conversacional, no como caption.
  final String headlineLabel;
  final String headlineValue;

  /// Línea pequeña bajo el valor destacado, ej. "Plazo: 12 meses".
  final String? subLabel;

  /// Fila que se muestra en un tamaño mayor que el resto (ej. "Pago mensual"),
  /// justo después del divisor.
  final (String, String)? emphasizedRow;

  /// Fila de intereses — se destaca en menta (#7FE8CE), igual que el
  /// prototipo, en vez del blanco plano del resto de las filas.
  final (String, String)? interestRow;

  /// Filas de detalle adicionales (label, value), tamaño normal.
  final List<(String, String)> rows;

  final String? footnote;

  static const _mint = AppColors.onPrimaryAccent;

  @override
  Widget build(BuildContext context) {
    final hasDetail = emphasizedRow != null || rows.isNotEmpty || interestRow != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF283593), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headlineLabel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w500)),
          const Gap(11),
          Text(headlineValue, style: AppTextStyles.heroNumber(40, color: Colors.white)),
          if (subLabel != null) ...[
            const Gap(6),
            Text(subLabel!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          if (hasDetail) ...[
            const Gap(16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
            const Gap(14),
          ],
          if (emphasizedRow != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(emphasizedRow!.$1, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(emphasizedRow!.$2,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              ],
            ),
            const Gap(10),
          ],
          for (final row in rows) _row(row.$1, row.$2),
          if (interestRow != null) _row(interestRow!.$1, interestRow!.$2, valueColor: _mint, valueWeight: FontWeight.w600),
          if (footnote != null) ...[
            const Gap(10),
            Text(footnote!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5, height: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color valueColor = Colors.white, FontWeight valueWeight = FontWeight.w700}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value, style: TextStyle(color: valueColor, fontWeight: valueWeight, fontSize: 15)),
          ],
        ),
      );
}
