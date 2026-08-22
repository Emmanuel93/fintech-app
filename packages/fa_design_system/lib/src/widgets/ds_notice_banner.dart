import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Tono de un [DsNoticeBanner]. El diseño usa el color para decir de qué tipo
/// es la advertencia, no para decorar: ámbar es "ojo con esto", azul es "así
/// funciona" y teal es "esto ya salió bien".
enum DsNoticeTone {
  /// Ámbar — la regla que puede costarte caro si la ignoras.
  /// `Kredius Journey App.dc.html` L1020–L1023, L1333–L1336.
  amber,

  /// Azul — la aclaración que quita una duda razonable. L1373–L1376.
  info,

  /// Teal — la confirmación de algo que ya ocurrió. L1112–L1115.
  success,
}

/// Aviso de una línea con marcador a la izquierda.
///
/// Es el patrón más repetido del journey de colocación: un rectángulo teñido,
/// un punto de 7 px alineado con la primera línea del texto y un párrafo de
/// 12/1.5 en peso 500. En el tono [DsNoticeTone.success] el punto se convierte
/// en una palomita, porque ahí el mensaje es un hecho consumado y no un aviso.
///
/// Se distingue de `DsInfoBanner` en el peso visual: aquél lleva icono en
/// círculo sólido y se usa para el sello de seguridad; éste es más callado y
/// se usa para reglas de negocio.
class DsNoticeBanner extends StatelessWidget {
  const DsNoticeBanner({
    super.key,
    required this.text,
    this.tone = DsNoticeTone.amber,
  });

  final String text;
  final DsNoticeTone tone;

  Color get _background => switch (tone) {
        DsNoticeTone.amber => AppColors.tertiaryContainer,
        DsNoticeTone.info => AppColors.primaryContainer,
        DsNoticeTone.success => AppColors.secondaryContainer,
      };

  Color get _marker => switch (tone) {
        DsNoticeTone.amber => AppColors.amberInk,
        DsNoticeTone.info => AppColors.primary,
        DsNoticeTone.success => AppColors.secondary,
      };

  Color get _foreground => switch (tone) {
        DsNoticeTone.amber => AppColors.onAmberContainer,
        DsNoticeTone.info => AppColors.onPrimaryContainer,
        DsNoticeTone.success => AppColors.onSecondaryContainer,
      };

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final isCheck = tone == DsNoticeTone.success;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ds.w(16), vertical: ds.h(14)),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(ds.r(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCheck)
            Container(
              width: ds.w(18),
              height: ds.w(18),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _marker, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded,
                  size: ds.sp(11), color: AppColors.onSecondary),
            )
          else
            Padding(
              // El punto se alinea con la primera línea del texto, no con el
              // borde de la caja: pegado arriba se lee como viñeta suelta.
              padding: EdgeInsets.only(top: ds.h(6)),
              child: Container(
                width: ds.w(7),
                height: ds.w(7),
                decoration: BoxDecoration(color: _marker, shape: BoxShape.circle),
              ),
            ),
          SizedBox(width: ds.w(11)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body(
                fontSize: ds.sp(12),
                weight: FontWeight.w500,
                color: _foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Viñeta con palomita en píldora azul — la lista que se despliega dentro de
/// una tarjeta de opción seleccionada (Journey App L1009–L1014).
class DsCheckBullet extends StatelessWidget {
  const DsCheckBullet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ds.w(15),
          height: ds.w(15),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: AppColors.primaryContainer, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded,
              size: ds.sp(9), color: AppColors.primary),
        ),
        SizedBox(width: ds.w(9)),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body(
              fontSize: ds.sp(12),
              weight: FontWeight.w500,
              color: AppColors.onPrimaryContainer,
            ).copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
