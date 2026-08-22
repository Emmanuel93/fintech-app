import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../providers/wallet_provider.dart';

enum _DestType { clabe, cuenta, celular }

enum _TxState { idle, processing, success, failure }

const _kBanks = [
  'BBVA',
  'Banamex (Citibanamex)',
  'Santander',
  'Banorte',
  'HSBC',
  'Scotiabank',
  'Inbursa',
  'Banco Azteca',
  'Hey Banco',
  'Nu México',
  'SPIN by OXXO',
  'Mercado Pago',
  'Otro',
];

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _destCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _conceptCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _DestType _destType = _DestType.celular;
  String? _selectedBank;
  int _step = 0;
  _TxState _txState = _TxState.idle;

  @override
  void dispose() {
    _destCtrl.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _conceptCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  int get _maxLen {
    switch (_destType) {
      case _DestType.clabe:
        return 18;
      case _DestType.cuenta:
        return 16;
      case _DestType.celular:
        return 10;
    }
  }

  String get _destLabel {
    switch (_destType) {
      case _DestType.clabe:
        return 'CLABE interbancaria';
      case _DestType.cuenta:
        return 'Número de cuenta';
      case _DestType.celular:
        return 'Número celular';
    }
  }

  String get _destHint {
    switch (_destType) {
      case _DestType.clabe:
        return '18 dígitos';
      case _DestType.cuenta:
        return '10 a 16 dígitos';
      case _DestType.celular:
        return '10 dígitos';
    }
  }

  String? _validateDest(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    switch (_destType) {
      case _DestType.clabe:
        if (v.length != 18) return 'La CLABE debe tener 18 dígitos';
      case _DestType.cuenta:
        if (v.length < 10) return 'Ingresa al menos 10 dígitos';
      case _DestType.celular:
        if (v.length != 10) return 'Ingresa 10 dígitos';
    }
    return null;
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el banco de destino')),
      );
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _confirm() async {
    setState(() => _txState = _TxState.processing);
    final results = await Future.wait([
      context.read<WalletProvider>().sendTransfer(
            destination: _destCtrl.text.trim(),
            destinationType: _destType.name,
            bank: _selectedBank!,
            beneficiaryName: _nameCtrl.text.trim(),
            amount: _amount,
            concept: _conceptCtrl.text.trim(),
          ),
      Future.delayed(const Duration(seconds: 4)),
    ]);
    if (!mounted) return;
    setState(() => _txState = (results[0] as bool) ? _TxState.success : _TxState.failure);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final provider = context.watch<WalletProvider>();
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    // Show full-screen animation overlay when processing or done
    if (_txState != _TxState.idle) {
      return _TransferAnimationScreen(
        txState: _txState,
        amount: _amount,
        beneficiaryName: _nameCtrl.text,
        fmt: fmt,
        onRetry: () => setState(() {
          _txState = _TxState.idle;
          _step = 1;
        }),
        onHome: () => context.go('/home'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => _step == 0 ? context.go('/home') : setState(() => _step = 0),
        ),
        title: Text(
          _step == 0 ? 'Transferencia SPEI' : 'Confirmar transferencia',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Step indicator ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.064, vertical: h * 0.015),
            child: Row(
              children: [
                _StepDot(active: true, label: '1', done: _step > 0),
                Expanded(
                    child: Divider(
                        color: _step > 0 ? AppColors.primary : AppColors.outlineVariant)),
                _StepDot(active: _step >= 1, label: '2', done: false),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.064),
              child: _step == 0
                  ? _FormStep(
                      formKey: _formKey,
                      destCtrl: _destCtrl,
                      nameCtrl: _nameCtrl,
                      amountCtrl: _amountCtrl,
                      conceptCtrl: _conceptCtrl,
                      destType: _destType,
                      selectedBank: _selectedBank,
                      balance: provider.wallet?.available ?? 0,
                      maxLen: _maxLen,
                      destLabel: _destLabel,
                      destHint: _destHint,
                      validateDest: _validateDest,
                      onDestTypeChanged: (t) => setState(() {
                        _destType = t;
                        _destCtrl.clear();
                      }),
                      onBankChanged: (b) => setState(() => _selectedBank = b),
                      h: h,
                      w: w,
                      theme: theme,
                    )
                  : _ConfirmStep(
                      destination: _destCtrl.text,
                      destType: _destType,
                      bank: _selectedBank!,
                      beneficiaryName: _nameCtrl.text,
                      amount: _amount,
                      concept: _conceptCtrl.text,
                      fmt: fmt,
                      h: h,
                      w: w,
                      theme: theme,
                    ),
            ),
          ),
          // ── Bottom actions ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.064, 0, w * 0.064, h * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsButton(
                  label: _step == 0 ? 'Continuar' : 'Confirmar transferencia',
                  onPressed: _step == 0 ? _next : _confirm,
                  isLoading: provider.isSending,
                  icon: _step == 1 ? Icons.send_rounded : null,
                ),
                Gap(h * 0.012),
                DsButton(
                  label: 'Cancelar',
                  variant: DsButtonVariant.ghost,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transfer animation full-screen ──────────────────────────────────────────
class _TransferAnimationScreen extends StatefulWidget {
  const _TransferAnimationScreen({
    required this.txState,
    required this.amount,
    required this.beneficiaryName,
    required this.fmt,
    required this.onRetry,
    required this.onHome,
  });

  final _TxState txState;
  final double amount;
  final String beneficiaryName;
  final NumberFormat fmt;
  final VoidCallback onRetry, onHome;

  @override
  State<_TransferAnimationScreen> createState() => _TransferAnimationScreenState();
}

class _TransferAnimationScreenState extends State<_TransferAnimationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _successCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(_TransferAnimationScreen old) {
    super.didUpdateWidget(old);
    if (old.txState != widget.txState &&
        (widget.txState == _TxState.success || widget.txState == _TxState.failure)) {
      _pulseCtrl.stop();
      _successCtrl.forward();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isSuccess = widget.txState == _TxState.success;
    final isDone =
        widget.txState == _TxState.success || widget.txState == _TxState.failure;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Centrado absoluto ──────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDone) ...[
                    // Outer pulse ring + inner icon
                    SizedBox(
                      width: h * 0.22,
                      height: h * 0.22,
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: h * 0.18 + (_pulseCtrl.value * h * 0.03),
                              height: h * 0.18 + (_pulseCtrl.value * h * 0.03),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                    alpha: 0.08 - (_pulseCtrl.value * 0.06)),
                              ),
                            ),
                            Container(
                              width: h * 0.14,
                              height: h * 0.14,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2),
                              ),
                              child: Icon(Icons.north_east_rounded,
                                  color: Colors.white, size: h * 0.055),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(h * 0.035),
                    _DotsLoader(color: Colors.white70, size: h * 0.012),
                    Gap(h * 0.022),
                    Text('Procesando transferencia...',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    Gap(h * 0.008),
                    Text('Esto tomará solo un momento',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white60)),
                  ] else ...[
                    // ── Success / failure ──────────────────────────
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: h * 0.15,
                        height: h * 0.15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSuccess
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          border: Border.all(
                              color: isSuccess ? AppColors.success : AppColors.error,
                              width: 3),
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_rounded : Icons.close_rounded,
                          color: isSuccess ? AppColors.success : AppColors.error,
                          size: h * 0.065,
                        ),
                      ),
                    ),
                    Gap(h * 0.04),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSuccess ? '¡Enviada!' : 'Error en la transferencia',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                          if (isSuccess) ...[
                            Gap(h * 0.012),
                            Text(
                              widget.fmt.format(widget.amount),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: h * 0.042,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1),
                            ),
                            Gap(h * 0.008),
                            Text('enviados a ${widget.beneficiaryName}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70)),
                          ] else ...[
                            Gap(h * 0.012),
                            Text('No pudimos completar la operación.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white60)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Botón inferior (solo cuando termina) ───────────────
            if (isDone)
              Positioned(
                bottom: h * 0.04,
                left: w * 0.1,
                right: w * 0.1,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: widget.onHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: h * 0.019),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text('Volver al inicio',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: h * 0.018)),
                      ),
                      if (!isSuccess) ...[
                        Gap(h * 0.012),
                        TextButton(
                          onPressed: widget.onRetry,
                          child: Text('Intentar de nuevo',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: h * 0.016)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated dots loader ────────────────────────────────────────────────────
class _DotsLoader extends StatefulWidget {
  const _DotsLoader({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (i / 3.0);
            final t = (_ctrl.value - offset) % 1.0;
            final scale = t < 0.5 ? 1.0 + t : 2.0 - t;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
              child: Transform.scale(
                scale: scale.clamp(0.6, 1.4),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                        alpha: (0.4 + (scale - 0.6) * 0.6).clamp(0.4, 1.0)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Step 1: Form ─────────────────────────────────────────────────────────────
class _FormStep extends StatelessWidget {
  const _FormStep({
    required this.formKey,
    required this.destCtrl,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.conceptCtrl,
    required this.destType,
    required this.selectedBank,
    required this.balance,
    required this.maxLen,
    required this.destLabel,
    required this.destHint,
    required this.validateDest,
    required this.onDestTypeChanged,
    required this.onBankChanged,
    required this.h,
    required this.w,
    required this.theme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController destCtrl, nameCtrl, amountCtrl, conceptCtrl;
  final _DestType destType;
  final String? selectedBank;
  final double balance, h, w;
  final int maxLen;
  final String destLabel, destHint;
  final String? Function(String?) validateDest;
  final void Function(_DestType) onDestTypeChanged;
  final void Function(String?) onBankChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Gap(h * 0.01),
          // Saldo disponible
          Container(
            padding: EdgeInsets.all(h * 0.015),
            decoration: BoxDecoration(
                color: AppColors.infoContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.info, size: 18),
                const Gap(8),
                Text('Saldo disponible: ${fmt.format(balance)}',
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.info)),
              ],
            ),
          ),
          Gap(h * 0.025),
          // ── Tipo de destino ──────────────────────────────────────────
          Text('Tipo de destino', style: theme.textTheme.labelMedium),
          Gap(h * 0.01),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: const [_DestType.celular, _DestType.cuenta, _DestType.clabe].map((t) {
                final selected = destType == t;
                final label = switch (t) {
                  _DestType.clabe => 'CLABE',
                  _DestType.cuenta => 'Cuenta',
                  _DestType.celular => 'Celular',
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDestTypeChanged(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(4),
                      padding: EdgeInsets.symmetric(vertical: h * 0.012),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.onSurfaceVariant,
                          fontSize: h * 0.015,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Gap(h * 0.018),
          // ── Campo destino ────────────────────────────────────────────
          DsTextField(
            label: destLabel,
            hint: destHint,
            controller: destCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(switch (destType) {
              _DestType.clabe => Icons.account_balance_outlined,
              _DestType.cuenta => Icons.credit_card_outlined,
              _DestType.celular => Icons.phone_outlined,
            }),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLen),
            ],
            validator: validateDest,
          ),
          Gap(h * 0.018),
          // ── Banco ────────────────────────────────────────────────────
          Text('Banco de destino', style: theme.textTheme.labelMedium),
          Gap(h * 0.01),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBank,
                hint: Text('Selecciona el banco',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.onSurfaceVariant),
                items: _kBanks
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b, style: theme.textTheme.bodyMedium),
                        ))
                    .toList(),
                onChanged: onBankChanged,
              ),
            ),
          ),
          Gap(h * 0.018),
          // ── Nombre del beneficiario ──────────────────────────────────
          DsTextField(
            label: 'Nombre del beneficiario',
            hint: 'Nombre completo',
            controller: nameCtrl,
            keyboardType: TextInputType.name,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Ingresa el nombre del beneficiario'
                : null,
          ),
          Gap(h * 0.022),
          // ── Monto ────────────────────────────────────────────────────
          Text('Monto', style: theme.textTheme.labelMedium),
          Gap(h * 0.01),
          DsTextField(
            label: 'Cantidad a enviar',
            hint: '0.00',
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.attach_money_rounded),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            validator: (v) {
              final val = double.tryParse(v?.replaceAll(',', '') ?? '');
              if (val == null || val <= 0) return 'Ingresa un monto válido';
              if (val > balance) return 'Saldo insuficiente';
              return null;
            },
          ),
          Gap(h * 0.018),
          // ── Concepto ─────────────────────────────────────────────────
          DsTextField(
            label: 'Concepto (opcional)',
            hint: 'Descripción del pago',
            controller: conceptCtrl,
            prefixIcon: const Icon(Icons.notes_rounded),
            maxLength: 40,
          ),
          Gap(h * 0.02),
        ],
      ),
    );
  }
}

// ─── Step 2: Confirm ─────────────────────────────────────────────────────────
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.destination,
    required this.destType,
    required this.bank,
    required this.beneficiaryName,
    required this.amount,
    required this.concept,
    required this.fmt,
    required this.h,
    required this.w,
    required this.theme,
  });

  final String destination, bank, beneficiaryName, concept;
  final _DestType destType;
  final double amount, h, w;
  final NumberFormat fmt;
  final ThemeData theme;

  String get _destTypeLabel => switch (destType) {
        _DestType.clabe => 'CLABE',
        _DestType.cuenta => 'Cuenta',
        _DestType.celular => 'Celular',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gap(h * 0.02),
        Container(
          padding: EdgeInsets.all(w * 0.06),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.onPrimaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.send_rounded, color: Colors.white70, size: 36),
              Gap(h * 0.012),
              Text('Enviando',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60)),
              Gap(h * 0.005),
              Text(fmt.format(amount),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              Gap(h * 0.008),
              Text('vía SPEI',
                  style: TextStyle(color: Colors.white38, fontSize: h * 0.014)),
            ],
          ),
        ),
        Gap(h * 0.025),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              _ConfirmRow(label: 'Beneficiario', value: beneficiaryName),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ConfirmRow(label: _destTypeLabel, value: destination),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ConfirmRow(label: 'Banco', value: bank),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ConfirmRow(
                  label: 'Concepto',
                  value: concept.isEmpty ? 'Sin concepto' : concept),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ConfirmRow(label: 'Comisión', value: '\$0.00'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ConfirmRow(
                  label: 'Total debitado', value: fmt.format(amount), bold: true),
            ],
          ),
        ),
        Gap(h * 0.02),
        Container(
          padding: EdgeInsets.all(h * 0.015),
          decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
              const Gap(8),
              Expanded(
                child: Text(
                  'Esta operación no es reversible. Verifica los datos antes de confirmar.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
        Gap(h * 0.02),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value, this.bold = false});
  final String label, value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: h * 0.014),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: bold ? AppColors.primary : AppColors.onSurface,
                )),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.label, required this.done});
  final bool active, done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary : AppColors.outlineVariant),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(label,
                style: TextStyle(
                    color: active ? Colors.white : AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}
