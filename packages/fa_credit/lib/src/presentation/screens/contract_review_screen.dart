import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';
import '../../domain/services/contract_pdf_builder.dart';
import '../providers/credit_application_provider.dart';

/// Lectura y firma del contrato.
///
/// Va entre el resumen y el código de un solo uso, y cierra el hueco que había:
/// antes se "aceptaba el contrato" sin que existiera un documento. Aquí el PDF
/// se genera de verdad, se puede leer y descargar, y la firma autógrafa que se
/// dibuja en el pad **se estampa sobre el documento** antes de firmarlo con el
/// código.
///
/// El clausulado sale de `ContractPdfBuilder`, que lo arma según el producto —
/// a plazo, revolvente o de colocación— así que agregar un producto nuevo no
/// exige una pantalla nueva.
class ContractReviewScreen extends StatefulWidget {
  const ContractReviewScreen({super.key});

  @override
  State<ContractReviewScreen> createState() => _ContractReviewScreenState();
}

class _ContractReviewScreenState extends State<ContractReviewScreen> {
  final _signature = DsSignatureController();
  Uint8List? _pdf;
  bool _building = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildPdf());
  }

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  ContractData? _data() {
    final provider = context.read<CreditApplicationProvider>();
    final app = provider.application;
    final product = provider.selectedProduct;
    if (app == null) return null;

    // La solicitud no siempre trae la tasa (el BFF la manda en el producto);
    // sin ella el clausulado imprimiría una cuota de $0.00.
    final rate = product?.nominalRate;
    final amount = app.offerAmountOrLine ?? 0;
    final term = app.offeredTerm;
    final estimate = AmortizationCalculator.estimateForApplication(
          app,
          paymentFrequency: product?.defaultPaymentFrequency,
        ) ??
        ((rate != null && term != null && amount > 0)
            ? AmortizationCalculator.estimate(
                amount: amount,
                termInMonths: term,
                nominalRateAnnual: rate,
                paymentFrequency: product?.defaultPaymentFrequency ?? 'MONTHLY',
              )
            : null);
    final purpose = AppSession.instance.purpose;

    return ContractData(
      contractNumber: app.contractNumber ?? 'KRD-PENDIENTE',
      holderName: provider.holderName,
      curp: provider.holderCurp,
      productName: product?.name ?? 'Crédito Kredius',
      behavior: product?.behavior ?? 'INSTALLMENT',
      amount: amount,
      annualRate: rate ?? 0,
      term: term,
      periodicPayment: estimate?.periodicPayment,
      totalRepayment: estimate?.totalRepayment,
      clabe: provider.stagedClabe ?? '',
      isDistributor: purpose.isDistribuidor,
      // Comisión estándar de colocación del prototipo (Journey L1184).
      commissionRate: purpose.isDistribuidor ? 0.035 : null,
    );
  }

  Future<void> _buildPdf({Uint8List? signature}) async {
    final data = _data();
    if (data == null) {
      if (mounted) context.go('/credit/apply');
      return;
    }
    setState(() => _building = true);
    final bytes = await ContractPdfBuilder.build(data, signature: signature);
    if (!mounted) return;
    setState(() {
      _pdf = bytes;
      _building = false;
    });
  }

  /// Estampa la firma en el documento y pasa al código, que es lo que le da
  /// validez jurídica junto con la autógrafa.
  Future<void> _signAndContinue() async {
    final png = await _signature.toPngBytes();
    if (png == null || !mounted) return;

    await _buildPdf(signature: png);
    if (!mounted) return;

    final provider = context.read<CreditApplicationProvider>();
    provider.stageSignedContract(pdf: _pdf, signature: png);
    context.go('/credit/apply/sign');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;

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
                    _BackButton(
                        onTap: () => context.go('/credit/apply/contract')),
                    SizedBox(width: ds.w(14)),
                    Expanded(
                      child: Text('Tu contrato',
                          style: AppTextStyles.cardTitle(fontSize: ds.sp(15))
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (_pdf != null)
                      GestureDetector(
                        onTap: () => Printing.sharePdf(
                          bytes: _pdf!,
                          filename: 'contrato-kredius.pdf',
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                          child: Text('Descargar',
                              style: AppTextStyles.body(
                                fontSize: ds.sp(12),
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                              ).copyWith(height: 1.0)),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: ds.h(14)),

              // Documento — se lee de verdad, no es una casilla de "acepto".
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: ds.gutter),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(ds.r(AppRadii.cardSmall)),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: _building || _pdf == null
                      ? const Center(child: CircularProgressIndicator())
                      : PdfPreview(
                          build: (_) => _pdf!,
                          useActions: false,
                          allowPrinting: false,
                          allowSharing: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          pdfPreviewPageDecoration: const BoxDecoration(
                            color: AppColors.surface,
                          ),
                          previewPageMargin: EdgeInsets.all(ds.w(8)),
                        ),
                ),
              ),

              // Firma autógrafa.
              SizedBox(height: ds.h(14)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ds.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('TU FIRMA',
                              style: AppTextStyles.captionLabel(
                                  fontSize: ds.sp(10))),
                        ),
                        AnimatedBuilder(
                          animation: _signature,
                          builder: (_, __) => _signature.isEmpty
                              ? const SizedBox.shrink()
                              : GestureDetector(
                                  onTap: _signature.clear,
                                  behavior: HitTestBehavior.opaque,
                                  child: Text('Borrar',
                                      style: AppTextStyles.body(
                                        fontSize: ds.sp(12),
                                        weight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ).copyWith(height: 1.0)),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: ds.h(9)),
                    DsSignaturePad(controller: _signature, height: 150),
                  ],
                ),
              ),

              SizedBox(height: ds.h(14)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutter, 0, ds.gutter, ds.bottomGap(24)),
                child: AnimatedBuilder(
                  animation: _signature,
                  builder: (_, __) => DsButton(
                    label: 'Estampar firma y continuar',
                    onPressed: _signature.isEmpty || _building
                        ? null
                        : _signAndContinue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
