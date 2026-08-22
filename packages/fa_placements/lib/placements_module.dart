import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'src/application/use_cases/placement_use_cases.dart';
import 'src/infrastructure/adapters/placement_repository_impl.dart';
import 'src/presentation/providers/placement_provider.dart';
import 'src/presentation/screens/beneficiaries_tab_screen.dart';
import 'src/presentation/screens/beneficiary_entry_screen.dart';
import 'src/presentation/screens/placement_amount_screen.dart';
import 'src/presentation/screens/placement_bureau_screen.dart';
import 'src/presentation/screens/placement_sent_screen.dart';
import 'src/presentation/screens/placements_tab_screen.dart';

/// Módulo de colocación B2B2C.
///
/// Aporta la tarjeta de línea al home, dos pestañas al nav (Colocaciones y
/// Beneficiarios) y el flujo de "Enviar préstamo". Todo eso **sólo existe si
/// hay línea autorizada**: para quien pidió crédito para sí, este módulo es
/// invisible.
class PlacementsModule extends IModule {
  late ApiClient _apiClient;
  // ignore: unused_field
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_placements';

  @override
  String get version => '1.0.0';

  @override
  void configure({
    required ApiClient apiClient,
    required NavigationCallbacks navigation,
  }) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<PlacementProvider>(
          create: (_) {
            final repo = PlacementRepositoryImpl(apiClient: _apiClient);
            return PlacementProvider(
              getLine: GetDistributorLineUseCase(repo),
              listPlacements: ListPlacementsUseCase(repo),
              getPlacement: GetPlacementUseCase(repo),
              createPlacement: CreatePlacementUseCase(repo),
              getBureauReport: GetBureauReportUseCase(repo),
              decidePlacement: DecidePlacementUseCase(repo),
              resendInvite: ResendInviteUseCase(repo),
              listBeneficiaries: ListBeneficiariesUseCase(repo),
            );
          },
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/placements/new',
          builder: (_, __) => const BeneficiaryEntryScreen(),
        ),
        GoRoute(
          path: '/placements/new/amount',
          builder: (_, state) => PlacementAmountScreen(
            // Lo capturado en el paso anterior viaja por `extra` y no por la
            // URL: son datos personales de un tercero y no tienen por qué
            // quedar en el historial de navegación.
            draft: (state.extra as Map?)?.cast<String, String>() ?? const {},
          ),
        ),
        GoRoute(
          path: '/placements/sent',
          builder: (_, __) => const PlacementSentScreen(),
        ),
        GoRoute(
          path: '/placements/:id/bureau',
          builder: (_, state) => PlacementBureauScreen(
            placementId: state.pathParameters['id'] ?? '',
          ),
        ),
      ];

  @override
  void initHome(BuildContext context) {
    // Se pregunta siempre, no sólo cuando el alta de esta sesión eligió
    // colocar: `AppSession.purpose` vive en memoria y se pierde al cerrar la
    // app, así que un distribuidor que vuelve a entrar con su usuario no
    // tendría propósito y el módulo entero desaparecería.
    //
    // Quien manda es el backend: `/distributor/line-summary` responde
    // `authorized: 0` para quien no coloca, y ésa es la única fuente que
    // sobrevive a un login.
    context.read<PlacementProvider>().load();
  }

  @override
  bool areTabsVisible(BuildContext context) =>
      context.watch<PlacementProvider>().hasLine;

  @override
  List<HomeTab> get ownedTabs =>
      const [HomeTab.colocaciones, HomeTab.beneficiarios];

  @override
  Widget buildTabScreen(BuildContext context, HomeTab tab) =>
      switch (tab) {
        HomeTab.colocaciones => const PlacementsTabScreen(),
        HomeTab.beneficiarios => const BeneficiariesTabScreen(),
        _ => const SizedBox.shrink(),
      };

  /// Primero de todo: la línea de colocación es el dinero del que responde
  /// el distribuidor, y de ella cuelga todo lo demás que hace en la app.
  @override
  int get homeCardOrder => 10;

  @override
  Widget? buildHomeCard(BuildContext context) {
    final provider = context.watch<PlacementProvider>();
    final line = provider.line;
    if (line == null) return null;

    final ds = context.ds;
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final fmtDate = DateFormat('dd MMM', 'es_MX');

    return Padding(
      padding: EdgeInsets.fromLTRB(ds.gutterWide, 0, ds.gutterWide, ds.h(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El diseño la reexportó como "Mi línea de distribuidor", pero la
          // sección de al lado sigue siendo "MIS CRÉDITOS": dos encabezados
          // hermanos con distinta caja se leen como dos jerarquías distintas.
          // Se mantienen ambos en versalitas.
          Text('MI LÍNEA DE DISTRIBUIDOR',
              style: AppTextStyles.captionLabel(fontSize: ds.sp(10))
                  .copyWith(height: 1.4)),
          SizedBox(height: ds.h(9)),
          DsLineSummaryCard(
            placed: fmt.format(line.placed),
            authorizedNote: 'de ${fmt.format(line.authorized)} autorizados',
            available: 'DISPONIBLE ${fmt.format(line.available)}',
            progress: line.usage,
            status: line.statusLabel,
            facts: [
              DsLineFact(
                  label: 'Total a cobrar', value: fmt.format(line.toCollect)),
              DsLineFact(
                  label: 'Pago a Kredius',
                  value: fmt.format(line.dueToKredius)),
              DsLineFact(
                label: 'Vencimiento',
                value: line.nextDueDate == null
                    ? '—'
                    : fmtDate.format(line.nextDueDate!),
              ),
              DsLineFact(
                label: 'Bonificación',
                value: fmt.format(line.commissionAccrued),
                good: true,
              ),
            ],
            ctaLabel: 'Enviar préstamo',
            onCta: () => context.go('/placements/new'),
          ),
        ],
      ),
    );
  }
}
