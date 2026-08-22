/// El bottom nav del home cambia de forma según el perfil.
///
/// Es la regla del diseño (Journey App L1701–L1708): quien pide para sí ve
/// Inicio · Movimientos · Oportunidades, y quien tiene línea de colocación ve
/// Inicio · Movimientos · Colocaciones · Beneficiarios — sin Oportunidades,
/// porque su acción principal ya no es contratar sino colocar.
///
/// Se prueba montando [HomeScreen] con módulos falsos en vez de recorrer el
/// alta completa: lo que hay que proteger es la composición del nav, y hacerla
/// depender de un journey de veinte pasos convertiría cualquier cambio del alta
/// en un fallo de este test.
library;

import 'package:fa_core/fa_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fa_shell/src/home/home_screen.dart';

class _FakeModule extends IModule {
  _FakeModule({
    required this.moduleId,
    this.tabs = const [],
    this.visible = true,
  });

  @override
  final String moduleId;

  final List<HomeTab> tabs;
  final bool visible;

  @override
  String get version => '1.0.0';

  @override
  void configure({
    required ApiClient apiClient,
    required NavigationCallbacks navigation,
  }) {}

  @override
  List<Widget> get providers => const [];

  @override
  List<RouteBase> get routes => const [];

  @override
  Widget? buildHomeCard(BuildContext context) => null;

  @override
  List<HomeTab> get ownedTabs => tabs;

  @override
  bool areTabsVisible(BuildContext context) => visible;

  @override
  Widget buildTabScreen(BuildContext context, HomeTab tab) =>
      Center(child: Text('contenido de ${tab.name}'));
}

Future<void> _mount(WidgetTester tester, List<IModule> modules) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(modules: modules),
  ));
  await tester.pump();
}

void main() {
  testWidgets('sin línea de colocación el nav ofrece Oportunidades',
      (tester) async {
    await _mount(tester, [
      _FakeModule(moduleId: 'wallet', tabs: const [HomeTab.movimientos]),
      _FakeModule(moduleId: 'placements', tabs: const [
        HomeTab.colocaciones,
        HomeTab.beneficiarios,
      ], visible: false),
    ]);

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Oportunidades'), findsOneWidget);
    expect(find.text('Colocaciones'), findsNothing);
    expect(find.text('Beneficiarios'), findsNothing);
  });

  testWidgets('con línea aparecen Colocaciones y Beneficiarios, y se va '
      'Oportunidades', (tester) async {
    await _mount(tester, [
      _FakeModule(moduleId: 'wallet', tabs: const [HomeTab.movimientos]),
      _FakeModule(moduleId: 'placements', tabs: const [
        HomeTab.colocaciones,
        HomeTab.beneficiarios,
      ]),
    ]);

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Colocaciones'), findsOneWidget);
    expect(find.text('Beneficiarios'), findsOneWidget);
    expect(find.text('Oportunidades'), findsNothing);
  });

  testWidgets('tocar una pestaña muestra el contenido de su módulo',
      (tester) async {
    await _mount(tester, [
      _FakeModule(moduleId: 'placements', tabs: const [HomeTab.colocaciones]),
    ]);

    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle();

    expect(find.text('contenido de colocaciones'), findsOneWidget);
  });

  testWidgets('si el tab activo desaparece, el home vuelve a Inicio en vez de '
      'enseñar otra pantalla', (tester) async {
    // Un distribuidor parado en "Beneficiarios" (índice 3) cuya línea deja de
    // estar disponible: sin el guardia, el IndexedStack pediría un hijo que ya
    // no existe.
    final placements = _FakeModule(moduleId: 'placements', tabs: const [
      HomeTab.colocaciones,
      HomeTab.beneficiarios,
    ]);
    final modules = <IModule>[
      _FakeModule(moduleId: 'wallet', tabs: const [HomeTab.movimientos]),
      placements,
    ];
    await _mount(tester, modules);

    await tester.tap(find.text('Beneficiarios'));
    await tester.pumpAndSettle();
    expect(find.text('contenido de beneficiarios'), findsOneWidget);

    // Se remonta sin el módulo de colocación (la línea se fue).
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(modules: [
        _FakeModule(moduleId: 'wallet', tabs: const [HomeTab.movimientos]),
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('contenido de beneficiarios'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
