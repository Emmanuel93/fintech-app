import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/placement.dart';
import '../providers/placement_provider.dart';

/// Pestaña "Colocaciones" — Journey App L804–L837.
///
/// Es la vista de operación: quién te debe, cuánto y en qué estado va. Las
/// fichas de las personas viven en la pestaña de Beneficiarios (L930), y esa
/// separación es deliberada: aquí se gestiona, allá se consulta.
class PlacementsTabScreen extends StatelessWidget {
  const PlacementsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<PlacementProvider>();
    final placements = provider.visiblePlacements;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            ds.gutterWide, ds.h(18), ds.gutterWide, ds.h(24)),
        children: [
          DsButton(
            label: 'Enviar préstamo',
            icon: Icons.arrow_forward_rounded,
            height: 48,
            onPressed: () => context.go('/placements/new'),
          ),
          SizedBox(height: ds.h(14)),
          DsFilterChips(
            labels: [for (final f in PlacementFilter.values) f.label],
            index: PlacementFilter.values.indexOf(provider.filter),
            onChanged: (i) => provider.setFilter(PlacementFilter.values[i]),
          ),
          SizedBox(height: ds.h(14)),
          if (provider.awaitingDecision.isNotEmpty &&
              provider.filter == PlacementFilter.todas) ...[
            // Lo que espera por él va arriba y aparte: en la lista corrida se
            // pierde justo la fila donde él es el que detiene el proceso.
            DsNoticeBanner(
              tone: DsNoticeTone.amber,
              text: provider.awaitingDecision.length == 1
                  ? '${provider.awaitingDecision.first.beneficiaryName} terminó '
                      'su verificación. Revisa su historial para decidir.'
                  : '${provider.awaitingDecision.length} personas terminaron su '
                      'verificación y esperan tu decisión.',
            ),
            SizedBox(height: ds.h(14)),
          ],
          if (placements.isEmpty)
            DsEmptyStateCard(
              icon: Icons.hub_outlined,
              title: provider.filter == PlacementFilter.todas
                  ? 'Todavía no has colocado'
                  : 'Nada en este filtro',
              message: provider.filter == PlacementFilter.todas
                  ? 'Tu línea está lista. Manda tu primer préstamo y aquí vas a '
                      'ver cómo va su cobro.'
                  : 'Prueba con otro filtro para ver el resto de tus '
                      'colocaciones.',
            )
          else
            DsListCard(
              children: [
                for (final (i, p) in placements.indexed)
                  _PlacementRow(
                    placement: p,
                    showDivider: i < placements.length - 1,
                  ),
              ],
            ),
          SizedBox(height: ds.h(12)),
          Text(
            'Estas son tus colocaciones vivas. Toca una para ver su expediente: '
            'sus pagos, su comisión y su gestión de cobro.',
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

class _PlacementRow extends StatelessWidget {
  const _PlacementRow({required this.placement, required this.showDivider});

  final Placement placement;
  final bool showDivider;

  /// El estado se dice con los días encima, no con un "con atraso" a secas:
  /// dos días y cinco días son comisiones distintas (20 % → 14 % → 0 %).
  (String, DsChipTone) get _status {
    if (placement.isOverdue) {
      final d = placement.daysPastDue;
      return ('ATRASO $d ${d == 1 ? 'DÍA' : 'DÍAS'}', DsChipTone.danger);
    }
    return switch (placement.status) {
      PlacementStatus.invited => ('LIGA ENVIADA', DsChipTone.info),
      PlacementStatus.kycInProgress => ('VERIFICÁNDOSE', DsChipTone.info),
      PlacementStatus.bureauReady => ('ESPERA TU OK', DsChipTone.warning),
      PlacementStatus.approved => ('DEPOSITANDO', DsChipTone.info),
      PlacementStatus.active => ('AL CORRIENTE', DsChipTone.ok),
      PlacementStatus.paidOff => ('LIQUIDÓ', DsChipTone.neutral),
      PlacementStatus.declined => ('NO COLOCADA', DsChipTone.neutral),
      PlacementStatus.expired => ('LIGA VENCIDA', DsChipTone.neutral),
      PlacementStatus.cancelled => ('CANCELADA', DsChipTone.neutral),
      // No es un estado neutro: algo se rompió y alguien tiene que volver a
      // intentarlo. Pintarlo en gris lo dejaría confundido con «cancelada».
      PlacementStatus.failed => ('NO SE COMPLETÓ', DsChipTone.danger),
    };
  }

  String get _meta {
    final fmtDate = DateFormat('dd MMM', 'es_MX');
    if (placement.status.isPending) {
      return 'Le mandaste la liga · ${placement.termFortnights} quincenas';
    }
    final placed = placement.placedOn;
    final cuando = placed == null ? '' : 'Colocada ${fmtDate.format(placed)} · ';
    return '$cuando${placement.paymentsMade} de '
        '${placement.termFortnights} quincenas';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PlacementProvider>();
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final (label, tone) = _status;
    final commission = placement.commissionAccrued;

    return DsPersonRow(
      name: placement.beneficiaryName,
      meta: _meta,
      chip: DsStatusChip(label: label, tone: tone, fontSize: 9),
      trailingValue: fmt.format(placement.amount),
      trailingNote: commission > 0 ? '+${fmt.format(commission)}' : null,
      trailingNoteGood: commission > 0,
      showDivider: showDivider,
      onTap: () {
        // La única fila que lleva a algún lado hoy es la que espera decisión:
        // es la que tiene una pantalla propia construida.
        if (placement.status == PlacementStatus.bureauReady) {
          context.go('/placements/${placement.id}/bureau');
        } else {
          provider.open(placement.id);
        }
      },
    );
  }
}
