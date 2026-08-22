import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../providers/credit_application_provider.dart';

/// Pantalla 9 del prototipo — "Tu código es tu firma" (Journey L522–L543,
/// cajas y teclado en L1241–L1255).
///
/// Seis cajas de 62px alimentadas por el **teclado del dispositivo**.
///
/// El prototipo dibuja un teclado numérico propio, y en el OTP del alta se
/// conserva. Aquí no: el código llega por SMS y el teclado del sistema ofrece
/// el autorrelleno del código recibido, que un teclado pintado no puede dar.
/// Tener los dos —el del sistema debajo y otro dibujado encima— es pedir que
/// se teclee dos veces lo mismo.
class ContractOtpScreen extends StatefulWidget {
  const ContractOtpScreen({super.key});

  @override
  State<ContractOtpScreen> createState() => _ContractOtpScreenState();
}

class _ContractOtpScreenState extends State<ContractOtpScreen> {
  static const int _length = 6;
  static const int _resendSeconds = 30;

  final _pin = GlobalKey<DsPinInputState>();
  bool _signing = false;
  int _secondsLeft = _resendSeconds;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  /// El código quedó completo: se firma sin pedir un botón de más.
  void _onCompleted(String code) {
    // 380ms para que se vea entrar el último dígito antes de cerrar el teclado.
    Future<void>.delayed(const Duration(milliseconds: 380), () => _sign(code));
  }

  Future<void> _sign(String code) async {
    if (!mounted || _signing) return;
    FocusScope.of(context).unfocus();
    setState(() => _signing = true);

    final provider = context.read<CreditApplicationProvider>();
    final ok = await provider.signStagedContract(signatureProof: code);
    if (!mounted) return;

    if (ok) {
      context.go('/credit/apply/done');
    } else {
      setState(() => _signing = false);
      _pin.currentState?.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.error ?? 'No pudimos firmar. Intenta de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final phone = context.read<CreditApplicationProvider>().maskedPhone;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          // Sin el teclado dibujado el contenido es corto y cabe arriba; con
          // el teclado del sistema abierto, en una pantalla corta ya no, así
          // que se deja scrollear en vez de desbordar.
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                ds.gutter, ds.topGap, ds.gutter, ds.bottomGap(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _BackButton(
                      onTap: _signing
                          ? null
                          : () => context.go('/credit/apply/contract'),
                    ),
                    SizedBox(width: ds.w(14)),
                    Expanded(
                      child: Text('Firma electrónica',
                          style: AppTextStyles.cardTitle(fontSize: ds.sp(15))
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                SizedBox(height: ds.h(24)),
                Text('Tu código es tu firma',
                    style: AppTextStyles.screenTitle(fontSize: ds.sp(27))),
                SizedBox(height: ds.h(6)),
                Text.rich(
                  TextSpan(
                    text: 'Te mandamos $_length dígitos al ',
                    style: AppTextStyles.body(fontSize: ds.sp(14)),
                    children: [
                      TextSpan(
                        text: phone,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(14),
                          weight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                SizedBox(height: ds.h(24)),

                // Cajas — Journey L531–L535. La firma usa borde de 2 y el
                // dígito en tinta; el OTP del alta, borde 1.5 y dígito azul.
                DsPinInput(
                  key: _pin,
                  length: _length,
                  onCompleted: _onCompleted,
                  onChanged: (_) => setState(() {}),
                  enabled: !_signing,
                ),
                SizedBox(height: ds.h(16)),
                if (_signing)
                  Row(
                    children: [
                      SizedBox(
                        width: ds.w(14),
                        height: ds.w(14),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: ds.w(10)),
                      Text('Firmando tu contrato…',
                          style: AppTextStyles.body(
                              fontSize: ds.sp(12.5), weight: FontWeight.w500)),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _secondsLeft == 0 ? _startCountdown : null,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      _secondsLeft == 0
                          ? 'Reenviar código'
                          : 'Reenviar código en 00:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: AppTextStyles.body(
                        fontSize: ds.sp(12.5),
                        weight: FontWeight.w500,
                        color: _secondsLeft == 0
                            ? AppColors.primary
                            : AppColors.disabled,
                      ).copyWith(height: 1.0),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: ds.w(38),
          height: ds.w(38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(12)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: ds.sp(18),
              color: onTap == null ? AppColors.disabled : AppColors.onSurface),
        ),
      ),
    );
  }
}
