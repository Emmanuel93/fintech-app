import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/beneficiary.dart';
import '../providers/placement_provider.dart';

/// Pestaña "Beneficiarios" — el directorio de personas (Journey App L873–L932).
///
/// A diferencia de Colocaciones, aquí no hay operación: es la ficha de cada
/// persona con su historial contigo, y desde ella se le vuelve a prestar.
class BeneficiariesTabScreen extends StatefulWidget {
  const BeneficiariesTabScreen({super.key});

  @override
  State<BeneficiariesTabScreen> createState() => _BeneficiariesTabScreenState();
}

class _BeneficiariesTabScreenState extends State<BeneficiariesTabScreen> {
  final _search = TextEditingController();
  String? _openPartyId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<PlacementProvider>();
    final list = provider.visibleBeneficiaries;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            ds.gutterWide, ds.h(18), ds.gutterWide, ds.h(24)),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mis beneficiarios',
                        style: AppTextStyles.sectionTitle(fontSize: ds.sp(17))),
                    SizedBox(height: ds.h(6)),
                    Text('Las personas a las que le has prestado',
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11.5),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.4)),
                  ],
                ),
              ),
              SizedBox(width: ds.w(12)),
              Text('${provider.beneficiaries.length}',
                  style: AppTextStyles.body(
                    fontSize: ds.sp(12),
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                  ).copyWith(height: 1.0)),
            ],
          ),
          SizedBox(height: ds.h(14)),
          DsSearchField(
            controller: _search,
            value: provider.beneficiaryQuery,
            hintText: 'Busca por nombre o celular',
            onChanged: provider.setBeneficiaryQuery,
          ),
          SizedBox(height: ds.h(14)),
          if (list.isEmpty)
            DsEmptyStateCard(
              icon: Icons.how_to_reg_outlined,
              title: provider.beneficiaryQuery.isEmpty
                  ? 'Todavía no tienes beneficiarios'
                  : 'Nadie con ese nombre',
              message: provider.beneficiaryQuery.isEmpty
                  ? 'En cuanto alguien complete su verificación, su ficha vive '
                      'aquí: su contrato, sus pagos y su historial contigo.'
                  : 'Prueba con otro nombre o con los últimos dígitos de su '
                      'celular.',
            )
          else
            DsListCard(
              children: [
                for (final (i, b) in list.indexed)
                  _BeneficiaryRow(
                    beneficiary: b,
                    open: _openPartyId == b.partyId,
                    onToggle: () => setState(() => _openPartyId =
                        _openPartyId == b.partyId ? null : b.partyId),
                    showDivider: i < list.length - 1 || _openPartyId == b.partyId,
                  ),
              ],
            ),
          SizedBox(height: ds.h(12)),
          Text(
            'Aquí vive la ficha de cada persona: su contrato, su tabla de pagos '
            'y su historial contigo. Las colocaciones vivas se gestionan en la '
            'pestaña de Colocaciones.',
            style: AppTextStyles.body(
              fontSize: ds.sp(11.5),
              color: AppColors.disabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeneficiaryRow extends StatelessWidget {
  const _BeneficiaryRow({
    required this.beneficiary,
    required this.open,
    required this.onToggle,
    required this.showDivider,
  });

  final Beneficiary beneficiary;
  final bool open;
  final VoidCallback onToggle;
  final bool showDivider;

  (String, DsChipTone) get _status => switch (beneficiary.status) {
        BeneficiaryStatus.active => ('ACTIVO', DsChipTone.ok),
        BeneficiaryStatus.overdue => ('ATRASO', DsChipTone.danger),
        BeneficiaryStatus.onboarding => ('EN ALTA', DsChipTone.warning),
        BeneficiaryStatus.paidOff => ('LIQUIDÓ', DsChipTone.neutral),
      };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final (label, tone) = _status;

    return DsPersonRow(
      name: beneficiary.name,
      meta: beneficiary.summary,
      chip: DsStatusChip(label: label, tone: tone, fontSize: 9),
      onTap: onToggle,
      showDivider: showDivider,
      expanded: !open
          ? null
          : Padding(
              padding: EdgeInsets.only(top: ds.h(14), bottom: ds.h(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FactGrid(facts: beneficiary.facts),
                  SizedBox(height: ds.h(12)),
                  Row(
                    children: [
                      Expanded(
                        child: _SoftAction(
                          icon: Icons.description_outlined,
                          label: 'Su contrato',
                          // El contrato es del beneficiario y todavía no hay
                          // endpoint que lo entregue al distribuidor. Se deja
                          // visible y desactivado en vez de omitirlo: la ficha
                          // sin sus dos documentos se lee incompleta.
                          onTap: null,
                        ),
                      ),
                      SizedBox(width: ds.w(8)),
                      Expanded(
                        child: _SoftAction(
                          icon: Icons.receipt_long_outlined,
                          label: 'Sus pagos',
                          onTap: null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ds.h(12)),
                  DsButton(
                    label: 'Enviarle otro préstamo',
                    height: 40,
                    onPressed: () => context.go('/placements/new'),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Rejilla 2×2 de la ficha — L905–L912.
class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<BeneficiaryFact> facts;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final rows = <Widget>[];

    for (var i = 0; i < facts.length; i += 2) {
      if (i > 0) rows.add(Container(height: 1, color: AppColors.divider));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Cell(fact: facts[i])),
            Container(width: 1, color: AppColors.divider),
            if (i + 1 < facts.length)
              Expanded(child: _Cell(fact: facts[i + 1]))
            else
              const Spacer(),
          ],
        ),
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(ds.r(12)),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
        child: Column(children: rows),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.fact});

  final BeneficiaryFact fact;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: ds.w(12), vertical: ds.h(11)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.label,
              style: AppTextStyles.body(
                fontSize: ds.sp(10.5),
                color: AppColors.disabled,
              ).copyWith(height: 1.0)),
          SizedBox(height: ds.h(7)),
          Text(fact.value,
              style: AppTextStyles.cardTitle(
                fontSize: ds.sp(13),
                color: fact.good
                    ? AppColors.secondary
                    : (fact.bad ? AppColors.error : AppColors.onSurface),
              ).copyWith(height: 1.0)),
        ],
      ),
    );
  }
}

class _SoftAction extends StatelessWidget {
  const _SoftAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final enabled = onTap != null;
    final color = enabled ? AppColors.primary : AppColors.disabled;

    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(ds.r(11)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ds.r(11)),
        child: Container(
          height: ds.h(40),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: ds.sp(15), color: color),
              SizedBox(width: ds.w(7)),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      fontSize: ds.sp(12.5),
                      weight: FontWeight.w600,
                      color: color,
                    ).copyWith(height: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
