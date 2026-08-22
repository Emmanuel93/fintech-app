import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import '../motion/kredius_motion.dart';

/// Celdas de un código de N dígitos.
///
/// El prototipo las usa en dos sitios con medidas ligeramente distintas:
/// - **OTP del alta** (Journey L217–L221): 60px, radio 14, borde 1.5, dígito en
///   `primary`.
/// - **Firma del contrato** (L531–L535): 62px, radio 14, borde 2, dígito en
///   `onSurface`.
///
/// La caja activa —la que recibirá el siguiente dígito— lleva el borde azul.
class DsPinCells extends StatelessWidget {
  const DsPinCells({
    super.key,
    required this.code,
    this.length = 6,
    this.height = 60,
    this.borderWidth = 1.5,
    this.digitColor = AppColors.primary,
    this.focused = true,
  });

  final String code;
  final int length;
  final double height;
  final double borderWidth;
  final Color digitColor;

  /// `false` mientras se procesa (firma en curso): ninguna caja se resalta.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Semantics(
      label: 'Código de $length dígitos, ${code.length} escritos',
      child: Row(
        children: [
          for (var i = 0; i < length; i++) ...[
            if (i > 0) SizedBox(width: ds.w(9)),
            Expanded(
              child: AnimatedContainer(
                duration: KrediusMotion.tab,
                height: ds.h(height),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(ds.r(14)),
                  border: Border.all(
                    color: (focused && code.length == i)
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: borderWidth,
                  ),
                ),
                child: Text(
                  i < code.length ? code[i] : '',
                  style: AppTextStyles.cardTitle(
                    fontSize: ds.sp(24),
                    color: digitColor,
                  ).copyWith(fontWeight: FontWeight.w700, height: 1.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Celdas de código alimentadas por el **teclado del dispositivo**.
///
/// El teclado propio (`DsPinKeypad`) tiene sentido cuando es el único que
/// aparece. En la firma del contrato no lo es: el código llega por SMS y el
/// teclado del sistema ofrece el autorrelleno del código recibido, que el
/// teclado dibujado no puede dar. Dos teclados numéricos en la misma pantalla
/// —uno del sistema y otro pintado— es teclear dos veces lo mismo.
///
/// Se apoya en un campo real invisible: así funcionan el pegado, el
/// autorrelleno de SMS y el teclado que el usuario ya sabe usar, mientras en
/// pantalla se ven las cajas del diseño.
class DsPinInput extends StatefulWidget {
  const DsPinInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.height = 62,
    this.borderWidth = 2,
    this.digitColor = AppColors.onSurface,
    this.enabled = true,
    this.autofocus = true,
  });

  /// Se llama una vez, cuando el código queda completo.
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  final int length;
  final double height;
  final double borderWidth;
  final Color digitColor;
  final bool enabled;
  final bool autofocus;

  @override
  State<DsPinInput> createState() => DsPinInputState();
}

class DsPinInputState extends State<DsPinInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  String get code => _controller.text;

  /// Vacía las cajas tras un código rechazado, sin cerrar el teclado.
  void clear() {
    _controller.clear();
    setState(() {});
    if (widget.enabled) _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (clipped != raw) {
      _controller.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
    }
    setState(() {});
    widget.onChanged?.call(clipped);
    if (clipped.length == widget.length) widget.onCompleted(clipped);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.enabled ? _focus.requestFocus : null,
          behavior: HitTestBehavior.opaque,
          child: DsPinCells(
            code: _controller.text,
            length: widget.length,
            height: widget.height,
            borderWidth: widget.borderWidth,
            digitColor: widget.digitColor,
            focused: widget.enabled,
          ),
        ),
        // El campo real: invisible pero presente, para que el sistema lo trate
        // como lo que es y ofrezca el código del SMS.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(height: 1),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: _onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
