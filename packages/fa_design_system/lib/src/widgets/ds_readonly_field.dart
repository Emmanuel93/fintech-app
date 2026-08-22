import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import 'ds_status_chip.dart';
import 'ds_translucent_field.dart' show dsFieldKey;

/// Dato ya capturado que se muestra, no se pide otra vez.
///
/// Existe para los datos que el flujo **ya recogió y validó** —el celular que
/// se verificó con el código, el correo que se dio junto a él—. Repetirlos
/// como campos vacíos hace pensar que algo se perdió; repetirlos como campos
/// llenos y editables invita a cambiar justo lo que se acaba de verificar.
///
/// Se ve como un campo, con su etiqueta y su caja, pero en tono de dato: fondo
/// tenue y sin cursor. Si de verdad hay que corregirlo, [onEdit] lleva al paso
/// donde se captura — que es el único sitio donde el cambio puede volver a
/// validarse.
class DsReadonlyField extends StatelessWidget {
  const DsReadonlyField({
    super.key,
    required this.label,
    required this.value,
    this.verified = false,
    this.onEdit,
    this.editLabel = 'Cambiar',
  });

  final String label;
  final String value;

  /// Muestra la palomita de verificado — sólo para lo que de verdad se validó.
  final bool verified;

  final VoidCallback? onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return Semantics(
      label: '$label: $value${verified ? ', verificado' : ''}',
      readOnly: true,
      child: Column(
        key: ValueKey(dsFieldKey(label)),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.fieldLabel(fontSize: ds.sp(11.5))),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: ds.w(2)),
                    child: Text(editLabel,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11.5),
                          weight: FontWeight.w600,
                          color: AppColors.primary,
                        ).copyWith(height: 1.0)),
                  ),
                ),
            ],
          ),
          SizedBox(height: ds.h(7)),
          Container(
            height: ds.h(48),
            padding: EdgeInsets.symmetric(horizontal: ds.w(14)),
            decoration: BoxDecoration(
              color: AppColors.fieldFillOnCard,
              borderRadius: BorderRadius.circular(ds.r(12)),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.inputText(
                      fontSize: ds.sp(14.5),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (verified) ...[
                  SizedBox(width: ds.w(8)),
                  const DsStatusChip(
                    label: 'VERIFICADO',
                    tone: DsChipTone.ok,
                    fontSize: 8.5,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
