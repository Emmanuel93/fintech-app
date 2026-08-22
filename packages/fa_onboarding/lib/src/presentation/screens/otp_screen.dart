import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../alta_step.dart';
import '../providers/kyc_provider.dart';

/// Paso 3 del alta — "Escribe el código que te mandamos"
/// (Journey L202–L240, datos en L1191–L1210).
///
/// Las cajas del diseño sobre el **teclado del dispositivo**. El prototipo
/// dibuja su propio teclado numérico, pero el código llega por SMS y el teclado
/// del sistema ofrece autorrellenarlo; uno pintado no puede, y tener los dos
/// obliga a teclear dos veces lo mismo.
///
/// Al completar los 6 dígitos verifica sola tras 420ms — el mismo respiro que
/// el prototipo, para que se vea entrar el último dígito.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _length = 6;
  static const int _resendSeconds = 47;

  final _pin = GlobalKey<DsPinInputState>();
  String _code = '';
  bool _hasError = false;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String code) {
    if (_code == code) return;
    setState(() {
      _code = code;
      _hasError = false;
    });
  }

  void _onCompleted(String code) {
    Future<void>.delayed(
        const Duration(milliseconds: 420), () => _verify(code));
  }

  Future<void> _verify(String code) async {
    if (!mounted || code.length < _length) return;
    final provider = context.read<KycProvider>();
    if (provider.isLoading) return;
    FocusScope.of(context).unfocus();
    final ok = await provider.verifyOtp(code);
    if (!mounted) return;
    if (ok) {
      context.go('/onboarding/identity');
    } else {
      setState(() => _hasError = true);
      _pin.currentState?.clear();
    }
  }

  Future<void> _resend() async {
    await context.read<KycProvider>().resendOtp();
    _startTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado')),
      );
    }
  }

  /// "5510026001" → "+52 55 •••• ••01" — el prototipo enmascara todos los
  /// dígitos salvo los 4 últimos (Journey L1162).
  String _maskedPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return raw;
    final visible = d.substring(d.length - 4);
    final hidden = '•' * (d.length - 4);
    return '+52 $hidden$visible';
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<KycProvider>();
    final phone = provider.state.phone;
    final isMock = AppConfig.current.flavor == AppFlavor.mock;

    return DsLoaderOverlay(
      isLoading: provider.isLoading,
      message: 'Verificando...',
      child: Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: SafeArea(
          child: DsResponsiveBody(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  ds.gutter, ds.topGap, ds.gutter, ds.bottomGap(28)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DsOnboardingTopBar(
                    step: AltaStep.codigo.number,
                    total: AltaStep.total,
                    onBack: () => context.go('/onboarding/phone'),
                  ),

                  // Tile de icono — Journey L211–L213.
                  SizedBox(height: ds.h(24)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: ds.w(52),
                      height: ds.w(52),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(ds.r(15)),
                      ),
                      child: Icon(Icons.smartphone_outlined,
                          size: ds.sp(24), color: AppColors.primary),
                    ),
                  ),
                  SizedBox(height: ds.h(18)),
                  Text('Escribe el código que te mandamos',
                      style: AppTextStyles.screenTitle(fontSize: ds.sp(27))),
                  SizedBox(height: ds.h(6)),
                  Text.rich(
                    TextSpan(
                      text: 'Enviamos un SMS de $_length dígitos al ',
                      style: AppTextStyles.body(fontSize: ds.sp(14)),
                      children: [
                        TextSpan(
                          text: _maskedPhone(phone),
                          style: AppTextStyles.body(
                            fontSize: ds.sp(14),
                            weight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const TextSpan(
                            text: '. Con esto queda firmada tu autorización.'),
                      ],
                    ),
                  ),

                  SizedBox(height: ds.h(22)),
                  DsPinInput(
                    key: _pin,
                    length: _length,
                    height: 60,
                    borderWidth: 1.5,
                    digitColor: AppColors.primary,
                    enabled: !provider.isLoading,
                    onChanged: _onChanged,
                    onCompleted: _onCompleted,
                  ),

                  if (_hasError) ...[
                    SizedBox(height: ds.h(12)),
                    Text('Código incorrecto. Intenta de nuevo.',
                        style: AppTextStyles.body(
                            fontSize: ds.sp(12.5), color: AppColors.error)),
                  ],

                  // Reenviar / Borrar — Journey L223–L226.
                  SizedBox(height: ds.h(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _secondsLeft == 0 ? _resend : null,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          _secondsLeft == 0
                              ? 'Reenviar código'
                              : 'Reenviar en 0:${_secondsLeft.toString().padLeft(2, '0')}',
                          style: AppTextStyles.body(
                            fontSize: ds.sp(12.5),
                            weight: _secondsLeft == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _secondsLeft == 0
                                ? AppColors.primary
                                : AppColors.disabled,
                          ).copyWith(height: 1.4),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _pin.currentState?.clear();
                          setState(() {
                            _code = '';
                            _hasError = false;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Text('Borrar',
                            style: AppTextStyles.body(
                              fontSize: ds.sp(12.5),
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                            ).copyWith(height: 1.4)),
                      ),
                    ],
                  ),

                  // La pista del código sólo tiene sentido donde no hay SMS.
                  if (isMock) ...[
                    SizedBox(height: ds.h(14)),
                    const DsInfoBanner(
                      icon: Icons.science_outlined,
                      text: 'Modo demo: el código es 123456.',
                    ),
                  ],

                  // Constancia legal — Journey L234–L239.
                  SizedBox(height: ds.h(14)),
                  const DsInfoBanner(
                    text:
                        'Guardamos la fecha, hora e IP de tu autorización como '
                        'constancia, según lo exige la ley.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
