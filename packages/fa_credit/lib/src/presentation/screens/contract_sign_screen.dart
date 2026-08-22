import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'package:fa_wallet/fa_wallet.dart';

import '../../domain/services/amortization_calculator.dart';
import '../providers/credit_application_provider.dart';

/// Pantalla 8 del prototipo — "Revisa y confirma" (Journey L465–L520,
/// filas del resumen L1216–L1224, destino del depósito L1225–L1234).
///
/// Resumen del préstamo, destino del depósito con las dos rutas del diseño
/// (CLABE ya registrada / capturar CLABE) y aceptación del contrato. Firmar
/// lleva a la pantalla de OTP, que es donde ocurre la firma electrónica.
class ContractSignScreen extends StatefulWidget {
  const ContractSignScreen({super.key});

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  final _clabe = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _accepted = false;

  /// CLABE ya registrada (cliente recurrente en un segundo producto) — un
  /// usuario nuevo sin cuenta previa simplemente no tendrá una.
  String? _existingClabe;

  /// 0 = "Ya tengo cuenta", 1 = "No tengo cuenta" (Journey L1225).
  int _depositTab = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final walletProv = context.read<WalletProvider>();
      if (walletProv.wallet == null) await walletProv.refresh();
      if (!mounted) return;
      final clabe = walletProv.wallet?.clabe;
      if (clabe != null && clabe.isNotEmpty) {
        setState(() {
          _existingClabe = clabe;
          _depositTab = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _clabe.dispose();
    super.dispose();
  }

  String get _digits => _clabe.text.replaceAll(RegExp(r'\D'), '');
  bool get _clabeValid => _digits.length == 18;

  bool get _canSign =>
      _accepted && (_depositTab == 0 ? _existingClabe != null : _clabeValid);

  void _toSign() {
    if (_depositTab == 1 && !_formKey.currentState!.validate()) return;
    final clabe = _depositTab == 0 ? _existingClabe! : _digits;
    context.read<CreditApplicationProvider>().stageClabe(clabe);
    context.go('/credit/apply/review');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditApplicationProvider>();
    final app = provider.application;

    if (app == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/credit/apply');
      });
      return const SizedBox.shrink();
    }

    // Firmado desde otra sesión / recarga: al desembolso.
    if (app.isContractSigned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/credit/apply/done');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final revolving = app.offeredLine != null;
    final amount = app.offerAmountOrLine ?? 0;
    // Mismas condiciones que el contrato y la tabla: un solo origen para que
    // las tres pantallas no puedan contradecirse.
    final terms = provider.scheduleTerms;
    final estimate = terms == null
        ? null
        : AmortizationCalculator.estimate(
            amount: terms.amount,
            termInMonths: terms.termInMonths,
            nominalRateAnnual: terms.annualRate,
            paymentFrequency: terms.paymentFrequency,
          );
    final primerPago = terms == null
        ? null
        : AmortizationCalculator.dueDate(
            n: 1, paymentFrequency: terms.paymentFrequency);

    final rows = <(String, String)>[
      ('Producto', provider.selectedProduct?.name ?? 'Crédito'),
      (revolving ? 'Línea autorizada' : 'Monto', fmt.format(amount)),
      if (estimate != null)
        ('Plazo', '${estimate.numPeriods} ${estimate.periodPlural}'),
      if (estimate != null)
        ('Pago ${estimate.periodLabel}', fmt.format(estimate.periodicPayment)),
      // Cuándo empieza a pagar es tan parte del trato como cuánto.
      if (primerPago != null)
        (
          'Primer pago',
          DateFormat("d 'de' MMMM 'de' y", 'es_MX').format(primerPago)
        ),
      if (estimate != null)
        ('Intereses incluidos', fmt.format(estimate.totalRepayment - amount)),
      if (estimate != null)
        ('Total a pagar', fmt.format(estimate.totalRepayment)),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding:
                    EdgeInsets.fromLTRB(ds.gutter, ds.topGap, ds.gutter, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.go('/credit/apply/offer')),
                    SizedBox(width: ds.w(14)),
                    Expanded(
                      child: Text('Revisa y confirma',
                          style: AppTextStyles.cardTitle(fontSize: ds.sp(15))
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(ds.gutter, ds.h(20), ds.gutter, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DsDetailCard(rows: rows, emphasizeLast: true),
                        SizedBox(height: ds.h(14)),
                        _buildDepositCard(ds),
                        SizedBox(height: ds.h(14)),
                        // Se pide aceptarla, así que tiene que poder leerse:
                        // aceptar un anexo invisible es firmar en blanco. Una
                        // línea revolvente no tiene calendario fijo, así que
                        // ahí no hay tabla que enseñar.
                        if (!revolving && estimate != null) ...[
                          DsDocumentLink(
                            label: 'Ver tabla de amortización',
                            caption: 'Fecha, monto e intereses de cada uno de '
                                'los ${estimate.numPeriods} pagos',
                            onTap: () => context.push('/credit/apply/schedule'),
                          ),
                          SizedBox(height: ds.h(14)),
                        ],
                        DsConsentCheck(
                          value: _accepted,
                          onChanged: (v) => setState(() => _accepted = v),
                          label: revolving
                              ? 'Acepto el contrato de crédito.'
                              : 'Acepto el contrato de crédito y la tabla de '
                                  'amortización.',
                        ),
                        if (provider.error != null) ...[
                          SizedBox(height: ds.h(10)),
                          Text(provider.error!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                  fontSize: ds.sp(12.5),
                                  color: AppColors.error)),
                        ],
                        SizedBox(height: ds.h(22)),
                        DsButton(
                          label: 'Leer y firmar contrato',
                          onPressed: _canSign ? _toSign : null,
                        ),
                        SizedBox(height: ds.bottomGap(28)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Journey L480–L513 — "DÓNDE TE DEPOSITAMOS".
  Widget _buildDepositCard(DsScale ds) {
    return Container(
      padding: EdgeInsets.all(ds.w(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(18)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('DÓNDE TE DEPOSITAMOS',
              style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
          SizedBox(height: ds.h(13)),
          DsSegmentedTabs(
            labels: const ['Ya tengo cuenta', 'No tengo cuenta'],
            index: _depositTab,
            height: 36,
            trackColor: AppColors.surfaceVariant,
            // Sin CLABE registrada no hay nada que mostrar en la primera.
            enabled: [_existingClabe != null, true],
            onChanged: (i) {
              if (i == 0 && _existingClabe == null) return;
              setState(() => _depositTab = i);
            },
          ),
          SizedBox(height: ds.h(13)),
          if (_depositTab == 0 && _existingClabe != null)
            _RegisteredAccountRow(clabe: _existingClabe!)
          else
            _buildClabeCapture(ds),
          SizedBox(height: ds.h(12)),
          Text('Recibes el dinero en menos de 15 minutos después de firmar.',
              style: AppTextStyles.body(fontSize: ds.sp(12))),
        ],
      ),
    );
  }

  Widget _buildClabeCapture(DsScale ds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsFormField(
          label: 'CLABE interbancaria (18 dígitos)',
          hint: '012 180 00000000000 0',
          controller: _clabe,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            LengthLimitingTextInputFormatter(22),
          ],
          onChanged: (_) => setState(() {}),
          validator: (_) =>
              _clabeValid ? null : 'La CLABE debe tener 18 dígitos',
        ),
        SizedBox(height: ds.h(8)),
        Text(
          _clabeValid
              ? 'CLABE válida · verificamos que la titularidad coincida con tu CURP.'
              : 'Te la damos de alta a tu nombre; validamos que la titularidad '
                  'coincida con tu CURP.',
          style: AppTextStyles.body(
            fontSize: ds.sp(11.5),
            color: _clabeValid ? AppColors.secondary : AppColors.disabled,
          ).copyWith(height: 1.4),
        ),
        SizedBox(height: ds.h(13)),
        const Divider(height: 1, color: AppColors.divider),
        SizedBox(height: ds.h(13)),
        // Journey L504–L509 — "Ábrete una cuenta Kredius".
        Row(
          children: [
            Container(
              width: ds.w(42),
              height: ds.w(42),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(ds.r(12)),
              ),
              child: Icon(Icons.add_rounded,
                  size: ds.sp(19), color: AppColors.primary),
            ),
            SizedBox(width: ds.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ábrete una cuenta Kredius',
                      style: AppTextStyles.cardTitle(fontSize: ds.sp(14))),
                  SizedBox(height: ds.h(5)),
                  Text(
                    'Sin CLABE propia: te damos una al firmar y depositamos ahí.',
                    style: AppTextStyles.body(
                      fontSize: ds.sp(11.5),
                      color: AppColors.disabled,
                    ).copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Journey L488–L494 — cuenta ya registrada y verificada.
class _RegisteredAccountRow extends StatelessWidget {
  const _RegisteredAccountRow({required this.clabe});
  final String clabe;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final last4 = clabe.length >= 4 ? clabe.substring(clabe.length - 4) : clabe;
    return Row(
      children: [
        Container(
          width: ds.w(42),
          height: ds.w(42),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(ds.r(12)),
          ),
          child: Icon(Icons.credit_card_rounded,
              size: ds.sp(19), color: AppColors.primary),
        ),
        SizedBox(width: ds.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•••• $last4',
                  style: AppTextStyles.cardTitle(fontSize: ds.sp(15))),
              SizedBox(height: ds.h(5)),
              Text('CLABE registrada y verificada a tu nombre',
                  style: AppTextStyles.body(
                    fontSize: ds.sp(11.5),
                    color: AppColors.disabled,
                  ).copyWith(height: 1.3)),
            ],
          ),
        ),
        SizedBox(width: ds.w(8)),
        const DsStatusChip(label: 'VERIFICADA'),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

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
              size: ds.sp(18), color: AppColors.onSurface),
        ),
      ),
    );
  }
}
