import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Key estable para localizar el campo en tests de integración, derivada de la
/// etiqueta. Sin ella el único anclaje es la posición del `Text` en el árbol —
/// frágil, porque la etiqueta es un hermano del input, no un ancestro.
String dsFieldKey(String label) => 'ds-field:$label';

/// Campo de texto sobre el héroe azul — login (Journey L89–L99, estilo L1045):
/// alto 52, radio 12, fondo `rgba(255,255,255,.10)`, borde `rgba(255,255,255,.20)`,
/// texto blanco 500/15, y etiqueta encima en mayúsculas al 60%.
///
/// `DsTextField` no sirve aquí: está construido para el fondo claro y su
/// `InputDecoration` viene del tema, que pinta relleno blanco.
class DsTranslucentField extends StatelessWidget {
  const DsTranslucentField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Widget al final del campo (ej. el toggle "Ver / Ocultar").
  final Widget? suffix;

  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(ds.r(12)),
      borderSide: BorderSide(color: AppColors.onPrimary.withValues(alpha: 0.20)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionLabel(
            fontSize: ds.sp(9.5),
            color: AppColors.onPrimary.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: ds.h(8)),
        TextFormField(
          key: ValueKey(dsFieldKey(label)),
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          enabled: enabled,
          cursorColor: AppColors.onPrimary,
          style: AppTextStyles.inputText(
              fontSize: ds.sp(15), color: AppColors.onPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.onPrimary.withValues(alpha: 0.10),
            hintText: hint,
            hintStyle: AppTextStyles.inputText(
              fontSize: ds.sp(15),
              color: AppColors.onPrimary.withValues(alpha: 0.45),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: ds.w(14), vertical: ds.h(17)),
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(
                  color: AppColors.onPrimary.withValues(alpha: 0.55), width: 1.5),
            ),
            errorBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
            ),
            errorStyle: AppTextStyles.body(
                fontSize: ds.sp(11.5), color: AppColors.tertiaryContainer),
            suffixIcon: suffix,
            suffixIconConstraints: BoxConstraints(minWidth: ds.w(44)),
          ),
        ),
      ],
    );
  }
}

/// Campo del alta con el look exacto del prototipo (Journey L187–L190, estilo
/// L1103): etiqueta 500/11.5 encima, caja blanca de 48 con radio 12, y el borde
/// que **vira a `#C9D4E5` cuando el campo tiene valor** — la señal visual de
/// "esto ya lo llenó el OCR" que distingue la pantalla de Datos.
class DsFormField extends StatelessWidget {
  const DsFormField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.maxLength,
    this.enabled = true,
    this.showLabel = true,
    this.height = 48,
    this.fillColor = AppColors.surface,
  });

  /// Etiqueta del campo. Se sigue exigiendo aunque [showLabel] sea `false`:
  /// de ella salen la key de test y la etiqueta de accesibilidad.
  final String label;

  /// `false` cuando la pantalla ya pinta el rótulo por su cuenta — por ejemplo
  /// la tarjeta de contacto del alta, donde un solo "NÚMERO CELULAR" encabeza
  /// el prefijo de país y el input (Journey L174–L181).
  final bool showLabel;

  /// Alto del input. 48 en el formulario de datos, 52 en la tarjeta de
  /// contacto (Journey L1163 vs L1272).
  final double height;

  /// Relleno. Blanco sobre el papel gris; `#F6F8FC` cuando el campo va dentro
  /// de una tarjeta blanca y necesita separarse del fondo.
  final Color fillColor;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final int? maxLength;
  final bool enabled;

  /// Borde del campo con valor — `#C9D4E5` en el prototipo.
  static const Color filledBorder = AppColors.filledBorder;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    // Sin controller no hay forma de reaccionar al contenido: se pinta el borde
    // vacío. Con controller, el borde vira a `filledBorder` en cuanto hay texto.
    if (ctrl == null) return _build(context, hasValue: false);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) =>
          _build(context, hasValue: value.text.isNotEmpty),
    );
  }

  Widget _build(BuildContext context, {required bool hasValue}) {
    final ds = DsScale.of(context);
    final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(ds.r(12)),
          borderSide: BorderSide(
              color: hasValue ? filledBorder : AppColors.outlineVariant),
        );

    // El alto se fija con el padding vertical: `isDense` + un contentPadding
    // calculado desde `height` mantiene la caja exactamente en la medida del
    // diseño sin envolverla en un SizedBox (que rompería el mensaje de error).
    final double vPad = ((ds.h(height) - ds.sp(14.5) * 1.2) / 2)
        .clamp(ds.h(8), ds.h(22));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label, style: AppTextStyles.fieldLabel(fontSize: ds.sp(11.5))),
          SizedBox(height: ds.h(7)),
        ],
        // Con la etiqueta oculta el lector de pantalla se quedaría sin
        // contexto, así que se la damos por Semantics.
        Semantics(
          textField: true,
          label: showLabel ? null : label,
          child: TextFormField(
            key: ValueKey(dsFieldKey(label)),
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            validator: validator,
            onChanged: onChanged,
            readOnly: readOnly,
            onTap: onTap,
            maxLength: maxLength,
            enabled: enabled,
            style: AppTextStyles.inputText(fontSize: ds.sp(14.5)),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fillColor,
              hintText: hint,
              counterText: '',
              hintStyle: AppTextStyles.inputText(
                  fontSize: ds.sp(14.5), color: AppColors.disabled),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: ds.w(14), vertical: vPad),
              border: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.6),
              ),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
