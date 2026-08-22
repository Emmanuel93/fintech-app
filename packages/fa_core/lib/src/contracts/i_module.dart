import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../network/api_client.dart';
import 'navigation_callbacks.dart';

/// Tab del bottom nav del home que un módulo puede poseer. Perfil y
/// notificaciones no son tabs a propósito — se abren desde el header.
///
/// El orden de la enumeración es el orden en que salen en el nav.
///
/// "Créditos" salió: el diseño nuevo (Journey App L1700, `tabCreditos: false`)
/// muestra los créditos activos en el carrusel de Inicio, y una pestaña con la
/// misma lista era una segunda puerta al mismo cuarto. La pantalla sigue viva
/// en la ruta `/credit/list`.
enum HomeTab { movimientos, colocaciones, beneficiarios }

abstract class IModule {
  String get moduleId;
  String get version;
  void configure({
    required ApiClient apiClient,
    required NavigationCallbacks navigation,
  });
  List<Widget> get providers;
  List<RouteBase> get routes;
  void initHome(BuildContext context) {}
  String? getHeaderDisplayName(BuildContext context) => null;
  int getHeaderBadgeCount(BuildContext context) => 0;
  Widget? buildHomeCard(BuildContext context);

  /// Posición de la card de este módulo en el tab "Inicio". Menor va primero.
  ///
  /// El orden del home es de **prelación**, no de estética: arriba el dinero
  /// del que el titular responde frente a Kredius —su línea de distribuidor,
  /// que arrastra la deuda de todas sus colocaciones—, después el que tomó
  /// para sí, y al final lo que se le ofrece. Quien abre la app viendo primero
  /// una promoción y hasta abajo su línea no está viendo su situación: está
  /// viendo un catálogo.
  ///
  /// Antes el orden lo daba el registro de módulos en `ShellInjection`, así
  /// que mover una línea de esa lista cambiaba silenciosamente la jerarquía
  /// del home. Declararlo aquí lo vuelve una decisión del módulo, visible y
  /// probada. Un módulo que no lo declara cae después de los que sí.
  int get homeCardOrder => 100;

  /// Tabs dedicados que este módulo aporta, o vacío si sólo pone una card en
  /// el tab "Inicio" (vía [buildHomeCard]).
  ///
  /// Es una lista y no un solo tab porque un módulo puede aportar más de una
  /// vista de primer nivel: colocación aporta *Colocaciones* y *Beneficiarios*,
  /// que son la operación y el directorio del mismo dominio.
  List<HomeTab> get ownedTabs => const [];

  /// Contenido de un tab declarado en [ownedTabs]. Sólo se llama con tabs de
  /// esa lista.
  Widget buildTabScreen(BuildContext context, HomeTab tab) =>
      const SizedBox.shrink();

  /// `false` esconde los tabs de este módulo **en este momento**. Se consulta
  /// en cada build del home, porque la respuesta depende del perfil y de lo que
  /// el cliente tenga contratado: sin línea de distribuidor no hay nada que
  /// colocar, y un tab que sólo puede enseñar un vacío es peor que no estar.
  bool areTabsVisible(BuildContext context) => true;
}
