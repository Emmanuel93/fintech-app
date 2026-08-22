import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/entities/credit_account.dart';
import '../providers/credit_provider.dart';

/// Cuerpo del tab "Créditos" del home (Fase 3/4) — historial completo del
/// prospecto, agrupado en vigentes/histórico, con detalle expandible por
/// crédito (`DsCreditListTile`).
class CreditsListScreen extends StatefulWidget {
  const CreditsListScreen({super.key});

  @override
  State<CreditsListScreen> createState() => _CreditsListScreenState();
}

class _CreditsListScreenState extends State<CreditsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreditProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditProvider>();

    if (provider.isLoadingAccounts && provider.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.accounts.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(ds.gutterWide),
        child: const Center(
          child: DsEmptyStateCard(
            icon: Icons.credit_card_outlined,
            title: 'Todavía no tienes créditos',
            message: 'Cuando contrates uno, aquí vas a ver su contrato y su '
                'tabla de pagos.',
          ),
        ),
      );
    }

    final vigentes = provider.accounts.where((a) => !a.isTerminal).toList();
    final historico = provider.accounts.where((a) => a.isTerminal).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.loadAccounts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            ds.gutterWide, ds.h(18), ds.gutterWide, ds.h(24)),
        children: [
          if (vigentes.isNotEmpty) ..._section(context, 'VIGENTES', vigentes),
          if (historico.isNotEmpty) ..._section(context, 'HISTÓRICO', historico),
          SizedBox(height: ds.h(4)),
          Text(
            'Toca un crédito para ver su contrato: la tabla cambia según el '
            'tipo de línea.',
            style: AppTextStyles.body(
              fontSize: ds.sp(11.5),
              color: AppColors.disabled,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(
      BuildContext context, String title, List<CreditAccount> accounts) {
    final ds = context.ds;
    return [
      Padding(
        padding: EdgeInsets.only(bottom: ds.h(9), top: ds.h(4)),
        child: Text(title, style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
      ),
      for (final account in accounts) _tileFor(account),
      SizedBox(height: ds.h(6)),
    ];
  }

  Widget _tileFor(CreditAccount account) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('d MMM yyyy', 'es_MX');
    final (statusLabel, statusColor) = switch (account.status.toUpperCase()) {
      'ACTIVE' => ('AL CORRIENTE', AppColors.secondary),
      'SUSPENDED' => ('SUSPENDIDO', AppColors.error),
      'RESTRUCTURED' => ('REESTRUCTURADO', AppColors.amberInk),
      'SETTLED' => ('LIQUIDADO', AppColors.mutedText),
      'WRITTEN_OFF' => ('CASTIGADO', AppColors.error),
      'CLOSED' => ('CERRADO', AppColors.mutedText),
      _ => (account.status, AppColors.mutedText),
    };

    return DsCreditListTile(
      icon: account.isRevolving ? Icons.credit_card_rounded : Icons.payments_rounded,
      title: account.displayTitle,
      statusLabel: statusLabel,
      statusColor: statusColor,
      amountLabel: fmt.format(account.isRevolving ? account.usedAmount : account.pendingBalance),
      amountSubLabel: account.isRevolving ? 'dispuesto' : 'saldo',
      tableLabel: account.isRevolving ? 'Tabla por disposición' : 'Tabla de pagos',
      detailRows: [
        (account.isRevolving ? 'Línea' : 'Monto original', fmt.format(account.creditLimit > 0
            ? account.creditLimit
            : account.usedAmount)),
        if (account.isRevolving)
          ('Disponible', fmt.format(account.availableCredit))
        else
          ('Mensualidades', account.assignedTerm != null ? '${account.assignedTerm}' : '—'),
        ('Corte', dateFmt.format(account.cutoffDate)),
        ('Próximo pago', dateFmt.format(account.paymentDueDate)),
      ],
    );
  }
}
