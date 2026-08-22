import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';
import '../../domain/services/amortization_pdf_builder.dart';
import '../providers/credit_application_provider.dart';

/// La tabla de amortización, visible.
///
/// El contrato la declara parte integrante y la casilla de firma pide
/// aceptarla; hasta ahora no se mostraba en ningún lado. Se abre desde el
/// resumen del préstamo y desde la pantalla de firma, y se puede descargar.
class AmortizationTableScreen extends StatefulWidget {
  const AmortizationTableScreen({super.key});

  @override
  State<AmortizationTableScreen> createState() =>
      _AmortizationTableScreenState();
}

class _AmortizationTableScreenState extends State<AmortizationTableScreen> {
  Uint8List? _pdf;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  Future<void> _build() async {
    final provider = context.read<CreditApplicationProvider>();
    final terms = provider.scheduleTerms;
    if (terms == null) {
      if (mounted) context.pop();
      return;
    }

    final rows = AmortizationCalculator.schedule(
      amount: terms.amount,
      termInMonths: terms.termInMonths,
      nominalRateAnnual: terms.annualRate,
      paymentFrequency: terms.paymentFrequency,
      from: terms.from,
    );
    final estimate = AmortizationCalculator.estimate(
      amount: terms.amount,
      termInMonths: terms.termInMonths,
      nominalRateAnnual: terms.annualRate,
      paymentFrequency: terms.paymentFrequency,
    );

    final bytes = await AmortizationPdfBuilder.build(
      rows: rows,
      amount: terms.amount,
      annualRate: terms.annualRate,
      periodAdjective: estimate?.periodAdjective ?? 'mensual',
      contractNumber: provider.application?.contractNumber,
      holderName: provider.holderName,
    );
    if (!mounted) return;
    setState(() => _pdf = bytes);
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
                    Semantics(
                      button: true,
                      label: 'Cerrar',
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: ds.w(38),
                          height: ds.w(38),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(ds.r(12)),
                            border:
                                Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: ds.sp(18), color: AppColors.onSurface),
                        ),
                      ),
                    ),
                    SizedBox(width: ds.w(14)),
                    Expanded(
                      child: Text('Tabla de amortización',
                          style: AppTextStyles.cardTitle(fontSize: ds.sp(15))
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (_pdf != null)
                      GestureDetector(
                        onTap: () => Printing.sharePdf(
                          bytes: _pdf!,
                          filename: 'tabla-amortizacion-kredius.pdf',
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
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                      ds.gutter, 0, ds.gutter, ds.bottomGap(20)),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(ds.r(AppRadii.cardSmall)),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: _pdf == null
                      ? const Center(child: CircularProgressIndicator())
                      : PdfPreview(
                          build: (_) => _pdf!,
                          useActions: false,
                          allowPrinting: false,
                          allowSharing: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          pdfPreviewPageDecoration:
                              const BoxDecoration(color: AppColors.surface),
                          previewPageMargin: EdgeInsets.all(ds.w(8)),
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
