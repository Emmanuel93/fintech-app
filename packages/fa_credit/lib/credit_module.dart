import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fa_design_system/fa_design_system.dart';

import 'package:fa_core/fa_core.dart';
import 'src/application/use_cases/get_credit_use_case.dart';
import 'src/application/use_cases/list_credit_accounts_use_case.dart';
import 'src/application/use_cases/make_payment_use_case.dart';
import 'src/application/use_cases/run_test_support_use_case.dart';
import 'src/application/use_cases/dispose_credit_use_case.dart';
import 'src/application/use_cases/list_products_use_case.dart';
import 'src/application/use_cases/list_prequalified_products_use_case.dart';
import 'src/application/use_cases/submit_application_use_case.dart';
import 'src/application/use_cases/get_application_use_case.dart';
import 'src/application/use_cases/present_offer_use_case.dart';
import 'src/application/use_cases/accept_offer_use_case.dart';
import 'src/application/use_cases/generate_contract_use_case.dart';
import 'src/application/use_cases/sign_contract_use_case.dart';
import 'src/domain/entities/credit_account.dart';
import 'src/infrastructure/adapters/credit_repository_impl.dart';
import 'src/presentation/providers/credit_provider.dart';
import 'src/presentation/providers/credit_application_provider.dart';
import 'src/presentation/screens/credit_detail_screen.dart';
import 'src/presentation/screens/credits_list_screen.dart';
import 'src/presentation/screens/product_selection_screen.dart';
import 'src/presentation/screens/application_amount_screen.dart';
import 'src/presentation/screens/application_status_screen.dart';
import 'src/presentation/screens/offer_screen.dart';
import 'src/presentation/screens/contract_sign_screen.dart';
import 'src/presentation/screens/contract_otp_screen.dart';
import 'src/presentation/screens/disbursement_success_screen.dart';
import 'src/presentation/screens/counter_offer_screen.dart';
import 'src/presentation/screens/rejected_screen.dart';
import 'src/presentation/screens/post_analysis_screen.dart';
import 'src/presentation/screens/amortization_table_screen.dart';
import 'src/presentation/screens/contract_review_screen.dart';

/// Título de la tarjeta de crédito del home según el producto (multi-segmento).
String creditCardTitle(CreditAccount c) => c.displayTitle;

class CreditModule extends IModule {
  late ApiClient _apiClient;
  // ignore: unused_field
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_credit';

  @override
  String get version => '1.0.0';

  @override
  void configure(
      {required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<CreditProvider>(
          create: (_) {
            final repo = CreditRepositoryImpl(apiClient: _apiClient);
            return CreditProvider(
              getCredit: GetCreditUseCase(repo),
              listCreditAccounts: ListCreditAccountsUseCase(repo),
              makePayment: MakePaymentUseCase(repo),
              runTestSupport: RunTestSupportUseCase(repo),
              disposeCredit: DisposeCreditUseCase(repo),
            );
          },
        ),
        ChangeNotifierProvider<CreditApplicationProvider>(
          create: (_) {
            final repo = CreditRepositoryImpl(apiClient: _apiClient);
            return CreditApplicationProvider(
              listProducts: ListProductsUseCase(repo),
              listPrequalifiedProducts: ListPrequalifiedProductsUseCase(repo),
              submitApplication: SubmitApplicationUseCase(repo),
              getApplication: GetApplicationUseCase(repo),
              presentOffer: PresentOfferUseCase(repo),
              acceptOffer: AcceptOfferUseCase(repo),
              generateContract: GenerateContractUseCase(repo),
              signContract: SignContractUseCase(repo),
            );
          },
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/credit',
          builder: (_, __) => const CreditDetailScreen(),
        ),
        // La lista dejó de ser pestaña (el carrusel de Inicio ya la cubre),
        // pero sigue siendo la vista correcta cuando hay muchos créditos y se
        // busca uno viejo. Se conserva como ruta, no como puerta permanente.
        GoRoute(
          path: '/credit/list',
          builder: (_, __) => const CreditsListScreen(),
        ),
        // Flujo de solicitud de crédito (separado del alta — ADR-001)
        // Continuación del análisis del alta: precalifica y rutea.
        GoRoute(
          path: '/credit/after-analysis',
          // Sin transición: es la segunda mitad del análisis que arrancó en el
          // alta. Animar la entrada la delata como pantalla distinta.
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const PostAnalysisScreen(),
          ),
        ),
        GoRoute(
          path: '/credit/apply',
          builder: (_, __) => const ProductSelectionScreen(),
        ),
        GoRoute(
          path: '/credit/apply/details',
          builder: (_, __) => const ApplicationAmountScreen(),
        ),
        GoRoute(
          // El consentimiento de buró salió del flujo: la autorización se
          // firma al abrir el alta y la consulta se hace en ese análisis.
          // Se conserva como redirect para no romper deep links.
          path: '/credit/apply/consent',
          redirect: (_, __) => '/credit/apply/details',
        ),
        // Se abre con push (encima del flujo) y se cierra con pop: es un
        // anexo que se consulta, no un paso más de la solicitud.
        GoRoute(
          path: '/credit/apply/schedule',
          builder: (_, __) => const AmortizationTableScreen(),
        ),
        GoRoute(
          path: '/credit/apply/status',
          builder: (_, __) => const ApplicationStatusScreen(),
        ),
        GoRoute(
          path: '/credit/apply/offer',
          builder: (_, __) => const OfferScreen(),
        ),
        GoRoute(
          path: '/credit/apply/rejected',
          builder: (_, __) => const RejectedScreen(),
        ),
        GoRoute(
          path: '/credit/apply/counter-offer',
          builder: (_, __) => const CounterOfferScreen(),
        ),
        GoRoute(
          path: '/credit/apply/contract',
          builder: (_, __) => const ContractSignScreen(),
        ),
        GoRoute(
          path: '/credit/apply/review',
          builder: (_, __) => const ContractReviewScreen(),
        ),
        GoRoute(
          path: '/credit/apply/sign',
          builder: (_, __) => const ContractOtpScreen(),
        ),
        GoRoute(
          path: '/credit/apply/done',
          builder: (_, __) => const DisbursementSuccessScreen(),
        ),
      ];

  @override
  void initHome(BuildContext context) {
    final creditProvider = context.read<CreditProvider>();
    final applicationProvider = context.read<CreditApplicationProvider>();
    // El fetch de precalificación solo importa si el prospecto no tiene crédito
    // todavía (si ya tiene uno, buildHomeCard nunca llega a la rama que la usa) —
    // encadenado tras el load() de CreditProvider, que ya se dispara en cada
    // carga/pull-to-refresh del home, cubre tanto "justo tras el registro" como
    // "cada vez que se abre el home".
    // La cartera completa hace falta desde el home y no sólo en el tab de
    // créditos: es de donde sale cuáles son propios y cuáles la línea de
    // colocación. Sin esto, un distribuidor con créditos veía el vacío.
    creditProvider.loadAccounts();
    creditProvider.load().then((_) {
      if (context.mounted && creditProvider.hasNoCredit) {
        applicationProvider.loadPrequalifiedProducts();
      }
    });
  }

  /// Después de la línea de colocación: son los créditos que el titular tomó
  /// para sí. La tarjeta de oportunidades va dentro de esta misma card, al
  /// final, que es donde el diseño pone lo que se ofrece (Journey L779).
  @override
  int get homeCardOrder => 20;

  @override
  Widget? buildHomeCard(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditProvider>();

    // La línea revolvente del distribuidor la pinta fa_placements, con el
    // vocabulario de la colocación (colocado, disponible, bonificación) y su
    // CTA de enviar préstamo. Repetirla aquí como "mi crédito" daría dos
    // tarjetas del mismo dinero contándolo distinto — y en el peor caso, un
    // "tu solicitud está en revisión" encima de una línea ya disponible. Así
    // que se saca de la cuenta, pero **sólo ella**: lo que este bloque muestra
    // son los créditos que el distribuidor tomó para sí, que son otro dinero.
    bool esLinea(CreditAccount? a) =>
        a != null && a.productType.toUpperCase() == 'DISTRIBUTOR_LINE';

    final accounts = provider.accounts.where((a) => !esLinea(a)).toList();
    // `provider.credit` puede ser justo la línea que se acaba de excluir, así
    // que el crédito a destacar sale de la lista ya filtrada. Si la cartera
    // todavía no llegó se cae al crédito suelto, que es lo que había antes:
    // así el home no se queda en blanco esperando la lista.
    final credit = accounts.isNotEmpty
        ? accounts.firstWhere(
            (a) => a.accountNumber == provider.credit?.accountNumber,
            orElse: () => accounts.first,
          )
        : (esLinea(provider.credit) ? null : provider.credit);

    // El home del prototipo (Journey L699–L795) tiene tres estados de crédito
    // y, debajo, la tarjeta de oportunidades — que aparece SIEMPRE, con o sin
    // crédito, sólo cambiando el copy (L1400–L1403).
    final application = context.watch<CreditApplicationProvider>();
    final purpose = AppSession.instance.purpose;

    // Un distribuidor con línea viva ya no está "en revisión" de nada: su
    // comité terminó. Sin esto vería el reloj de arena encima de una línea
    // aprobada, que es justo la contradicción que se quería evitar.
    final enComite =
        application.isPendingReview && !AppSession.instance.hasDistributorLine;

    final Widget creditBlock;
    if (!provider.loaded) {
      creditBlock = const _CreditCardSkeleton();
    } else if (credit == null && enComite) {
      // Nada aprobado pero sí productos en comité — el caso del distribuidor.
      // Se dice en qué va, en vez del vacío genérico.
      creditBlock = DsEmptyStateCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Tu solicitud está en revisión',
        message: purpose.isDistribuidor
            ? 'Un comité está evaluando tu línea de colocación. Te avisamos en '
                'cuanto haya respuesta — no tienes que hacer nada.'
            : 'Estamos revisando tu solicitud con más detalle. Te avisamos en '
                'cuanto haya respuesta.',
      );
    } else if (credit == null) {
      // Tocarla lleva al catálogo. Para quien tiene línea de colocación es la
      // única puerta: su nav son Inicio/Movimientos/Colocaciones/Beneficiarios
      // (Journey L1719–L1722) y ahí no cabe Oportunidades, así que sin esto un
      // distribuidor no tendría cómo tomar un crédito para sí mismo.
      creditBlock = DsEmptyStateCard(
        icon: Icons.credit_card_outlined,
        title: 'Todavía no tienes un crédito',
        message: 'Ya pasaste la revisión, así que lo que sigue es escoger. '
            'Tómate tu tiempo: la oferta no se vence hoy.',
        semanticLabel: 'Ver oportunidades de crédito',
        onTap: () => context.go('/credit/apply'),
      );
    } else if (accounts.length > 1) {
      creditBlock = _ActiveCreditsCarousel(accounts: accounts);
    } else {
      // La misma tarjeta del carrusel, a todo lo ancho: el diseño no tiene una
      // tarjeta distinta para "un solo crédito", sólo cambia el ancho (L2095).
      // Y con su encabezado, que el diseño pone haya uno o haya varios.
      creditBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _encabezadoDeCreditos(context),
          SizedBox(height: ds.h(11)),
          _tarjetaDeCredito(context, credit, width: null),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ds.gutterWide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          creditBlock,
          // La tarjeta de oportunidades no aparece si no hay nada que ofrecer:
          // en revisión, lo honesto es no empujar a un catálogo vacío.
          if (!enComite) ...[
            SizedBox(height: ds.h(14)),
            DsPromoCard(
              title: credit == null
                  ? 'Tenemos oportunidades listas para ti'
                  : 'Todavía hay más para ti',
              message: credit == null
                  ? 'Tu perfil abrió líneas de crédito. Míralas con calma y toma '
                      'la que te cuadre — no tienes que decidir hoy.'
                  : 'Además de lo que ya tienes, hay líneas disponibles esperando '
                      'el día que las necesites.',
              ctaLabel: 'Ver mis oportunidades',
              onTap: () => context.go('/credit/apply'),
            ),
          ],
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjetas del home — Journey L699–L795
// ─────────────────────────────────────────────────────────────────────────────

/// Encabezado de la sección de créditos propios — Journey L766–L768.
///
/// El diseño lo pinta **siempre que haya al menos un crédito**, con uno o con
/// varios (`hasOwn` envuelve tanto la tarjeta sola como el carrusel). Vivía
/// dentro del carrusel, así que quien tenía un único crédito veía la tarjeta
/// suelta, sin decir de qué sección era ni cómo llegar al resto.
Widget _encabezadoDeCreditos(BuildContext context) {
  final ds = context.ds;
  return Row(
    children: [
      Expanded(
        child: Text('MIS CRÉDITOS',
            style: AppTextStyles.captionLabel(fontSize: ds.sp(10))
                .copyWith(height: 1.4)),
      ),
      GestureDetector(
        onTap: () => context.go('/credit'),
        behavior: HitTestBehavior.opaque,
        child: Text('Ver todos',
            style: AppTextStyles.body(
              fontSize: ds.sp(12),
              weight: FontWeight.w600,
              color: AppColors.primary,
            ).copyWith(height: 1.0)),
      ),
    ],
  );
}

/// La tarjeta azul de un crédito activo — Journey L764–L790.
///
/// Vive aquí y no duplicada en dos lugares porque el diseño usa **la misma**
/// para un crédito y para varios: lo único que cambia es el ancho (100% cuando
/// está solo, 252 en el carrusel). Antes el caso de uno solo tenía su propia
/// tarjeta blanca, que era el lenguaje anterior y no el del diseño.
Widget _tarjetaDeCredito(
  BuildContext context,
  CreditAccount c, {
  // 252 es el ancho del carrusel; `null` estira la tarjeta a todo el renglón,
  // que es como se ve cuando hay un solo crédito. El default es el del
  // carrusel porque dejarlo en `null` le daba ancho infinito dentro del
  // `ListView` horizontal.
  double? width = 252,
}) {
  final fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
  final term = c.assignedTerm;
  return DsActiveCreditCard(
    width: width,
    name: c.displayTitle,
    meta: c.isRevolving
        ? 'Dispón cuando quieras · ${fmt.format(c.creditLimit)} de línea'
        : 'Contratado ${DateFormat('dd MMM', 'es_MX').format(c.cutoffDate)}'
            '${term != null ? ' · $term pagos' : ''}',
    status: c.isRevolving
        ? 'DISPONIBLE'
        : c.isPaidOff
            ? 'LIQUIDADO'
            : (c.isOverdue ? 'EN MORA' : 'AL CORRIENTE'),
    balance: fmt.format(c.isRevolving ? c.usedAmount : c.pendingBalance),
    nextLabel: c.isRevolving ? 'Corte' : 'Próximo pago',
    nextValue: c.isRevolving
        ? DateFormat('dd MMM', 'es_MX').format(c.cutoffDate)
        : fmt.format(c.minimumPayment),
    progress: c.isRevolving ? c.usedPercentage : (c.paymentProgress ?? 0),
    progressLabel: c.isRevolving
        ? '${fmt.format(c.availableCredit)} DISPONIBLES'
        : (c.paymentsMade != null && term != null
            ? '${c.paymentsMade} DE $term PAGOS'
            : 'PLAN A PLAZO'),
    ctaLabel:
        c.isRevolving ? 'Disponer' : 'Pagar ${fmt.format(c.minimumPayment)}',
    // El botón hace lo que dice: pagar cobra desde aquí, con su hoja de
    // confirmación, porque el home es donde se ve que el saldo se movió.
    // Disponer sí lleva al detalle, que es donde se elige el monto.
    onCta: () => c.isRevolving
        ? context.go('/credit')
        : _confirmarPago(context, c),
  );
}



/// Confirma y aplica el pago desde el home.
///
/// El pago vive aquí y no en el tab de Créditos porque el home es donde el
/// usuario ve que su saldo se movió: mandarlo a otra pantalla para volver a la
/// misma tarjeta es un rodeo. La hoja dice exactamente qué se va a cobrar antes
/// de cobrarlo — un botón que descuenta dinero al primer toque no se perdona.
Future<void> _confirmarPago(BuildContext context, CreditAccount credit) async {
  final fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  final provider = context.read<CreditProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmado = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final ds = sheetContext.ds;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              ds.gutter, ds.h(20), ds.gutter, ds.bottomGap(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Confirma tu pago',
                  style: AppTextStyles.sectionTitle(fontSize: ds.sp(19))),
              SizedBox(height: ds.h(6)),
              Text(
                'Se cargará a tu cuenta ${credit.accountNumber} y se '
                'aplica en el momento.',
                style: AppTextStyles.body(fontSize: ds.sp(13)),
              ),
              SizedBox(height: ds.h(16)),
              DsDetailCard(
                rows: [
                  ('Pago', fmt.format(credit.minimumPayment)),
                  ('Saldo actual', fmt.format(credit.pendingBalance)),
                  (
                    'Saldo después',
                    fmt.format((credit.pendingBalance - credit.minimumPayment)
                        .clamp(0, double.infinity))
                  ),
                ],
                emphasizeLast: true,
              ),
              SizedBox(height: ds.h(18)),
              DsButton(
                // Distinto del CTA de la tarjeta: "confirmar" es el acto que
                // cobra, y quien lo lee tiene que saber que ya no hay vuelta.
                label: 'Confirmar pago de ${fmt.format(credit.minimumPayment)}',
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              SizedBox(height: ds.h(8)),
              DsButton(
                label: 'Ahora no',
                variant: DsButtonVariant.outlined,
                onPressed: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmado != true) return;
  final ok = await provider.makePayment(amount: credit.minimumPayment);
  // Se relee del BFF: el descuento local no sabe cómo se reparte el pago entre
  // interés y capital, cuántas mensualidades van ni cuándo vence la siguiente
  // — y eso es justo lo que la tarjeta muestra. `load()` refresca `credit`,
  // que es de donde lee el home; `loadAccounts()` alimenta el tab de Créditos.
  if (ok) await provider.load();
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Pago aplicado. Tu saldo ya está actualizado.'
        : 'No pudimos aplicar el pago. Intenta de nuevo.'),
  ));
}

/// Varios créditos activos — carrusel horizontal (Journey L744–L777).
class _ActiveCreditsCarousel extends StatefulWidget {
  const _ActiveCreditsCarousel({required this.accounts});
  final List<CreditAccount> accounts;

  @override
  State<_ActiveCreditsCarousel> createState() => _ActiveCreditsCarouselState();
}

class _ActiveCreditsCarouselState extends State<_ActiveCreditsCarousel> {
  final _scroll = ScrollController();
  int _index = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final cardWidth = ds.w(252 + 11);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezadoDeCreditos(context),
        SizedBox(height: ds.h(11)),
        SizedBox(
          // El alto lo fija el carrusel, no la tarjeta: dentro de un `ListView`
          // horizontal la tarjeta no puede medirse sola. 276 era para la
          // tarjeta anterior; con las medidas nuevas —padding 16, gaps 11,
          // importe 22, CTA 37— sobraba azul debajo del botón.
          height: ds.h(250),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              final i = (_scroll.offset / cardWidth).round();
              if (i != _index && i >= 0 && i < widget.accounts.length) {
                setState(() => _index = i);
              }
              return false;
            },
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: widget.accounts.length,
              separatorBuilder: (_, __) => SizedBox(width: ds.w(11)),
              itemBuilder: (_, i) {
                return _tarjetaDeCredito(context, widget.accounts[i]);
              },
            ),
          ),
        ),
        SizedBox(height: ds.h(10)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.accounts.length; i++) ...[
              if (i > 0) SizedBox(width: ds.w(5)),
              KrDot(
                active: i == _index,
                size: ds.w(6),
                activeWidth: ds.w(16),
                color: AppColors.dotInactive,
              ),
            ],
          ],
        ),
      ],
    );
  }

}

/// Esqueleto mientras carga la cuenta.
class _CreditCardSkeleton extends StatelessWidget {
  const _CreditCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: EdgeInsets.all(ds.w(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar(ds, 0.45, 14),
          SizedBox(height: ds.h(14)),
          _bar(ds, 0.7, 28),
          SizedBox(height: ds.h(16)),
          _bar(ds, 1, 8),
          SizedBox(height: ds.h(16)),
          _bar(ds, 1, 60),
        ],
      ),
    );
  }

  Widget _bar(DsScale ds, double widthFactor, double height) =>
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: ds.h(height),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(ds.r(8)),
          ),
        ),
      );
}
