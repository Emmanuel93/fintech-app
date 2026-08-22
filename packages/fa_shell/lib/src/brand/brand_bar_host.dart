import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

/// Monta la [DsBrandBar] **encima de toda la app**, como en el diseño.
///
/// El Journey App no pinta la barra dentro de cada pantalla: la deja absoluta
/// sobre el marco del dispositivo (`position:absolute;top:44px;z-index:5`,
/// L1733) y cada pantalla abre con `padding-top:96px` para no quedar debajo.
/// Aquí se hace igual con un [Stack] a la altura del `MaterialApp`. El hueco no
/// se reparte desde aquí: ya viene en los paddings del diseño y lo aplica
/// [DsScale] (`topGap` subió de 62 a 96; `topGapBand` abre en 112). Así los
/// fondos a sangre —el azul de marca de los héroes— siguen pintando por debajo
/// de la barra en vez de quedar recortados por un área segura inflada.
///
/// Colgarla del router y no de cada pantalla evita además que parpadee entre
/// navegaciones: es el mismo widget, que permanece mientras las pantallas pasan.
class BrandBarHost extends StatefulWidget {
  const BrandBarHost({
    super.key,
    required this.router,
    required this.modules,
    required this.child,
  });

  final GoRouter router;

  /// Los mismos módulos del home: de ahí salen el nombre y las no leídas, por
  /// el contrato que ya existe ([IModule.getHeaderDisplayName]).
  final List<IModule> modules;

  final Widget child;

  /// Sin barra: la bienvenida y el login son la marca a pantalla completa, así
  /// que una segunda firma arriba sobra (`showBrand: !(login || screen 0)`).
  /// El splash es de la app, no del prototipo, y va por lo mismo.
  static const _sinBarra = {
    '/splash',
    '/login',
    '/onboarding',
    '/onboarding/welcome',
  };

  /// Con avatar y campana: dentro de la app (`inApp = [13, 16]`). En el alta el
  /// hueco se conserva pero se oculta el contenido, para que el logo no baile.
  static const _conAcciones = {'/home', '/notifications'};

  /// Pantallas cuyo fondo es blanco y no el papel `surfaceVariant`. Sólo se
  /// usa para teñir la franja que tapa el contenido al hacer scroll: si se
  /// pintara papel sobre una pantalla blanca se vería una costura.
  static const _blancas = {
    '/onboarding/identity',
    '/wallet/movements',
  };

  /// Tratamiento sobre el azul de marca (`brandDark`). Son las pantallas que
  /// abren con héroe azul: análisis, aprobación, desembolso, contraoferta,
  /// rechazo y la liga enviada a la beneficiaria.
  ///
  /// El diseño omite el análisis de su lista, pero ahí el fondo también es azul
  /// a sangre y el wordmark azul quedaría invisible: se trata como oscura.
  static const _oscuras = {
    '/onboarding/analysis',
    '/credit/after-analysis',
    '/credit/apply/status',
    '/credit/apply/done',
    '/credit/apply/counter-offer',
    '/credit/apply/rejected',
    '/placements/sent',
    // El perfil de la app es azul a sangre (el diseño lo resuelve como tab
    // del home); mientras siga siéndolo, la barra va en su versión oscura.
    '/profile',
  };

  @override
  State<BrandBarHost> createState() => _BrandBarHostState();
}

class _BrandBarHostState extends State<BrandBarHost> {
  late String _ruta;

  @override
  void initState() {
    super.initState();
    _ruta = _rutaActual;
    widget.router.routerDelegate.addListener(_alNavegar);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_alNavegar);
    super.dispose();
  }

  String get _rutaActual =>
      widget.router.routerDelegate.currentConfiguration.uri.path;

  /// El delegate avisa **durante** el build del `Navigator` —esta barra cuelga
  /// del `MaterialApp`, o sea por encima—, así que un `setState` directo caería
  /// en "marcó sucio un ancestro que ya se está construyendo". Se aplaza al
  /// final del frame, que además es cuando la ruta ya quedó firme.
  void _alNavegar() {
    final nueva = _rutaActual;
    if (nueva == _ruta) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      setState(() => _ruta = nueva);
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rutaActual != _ruta) setState(() => _ruta = _rutaActual);
    });
  }

  /// El color que hay detrás de la barra en esta ruta.
  Color _fondo(String ruta) {
    if (BrandBarHost._oscuras.contains(ruta)) return AppColors.primary;
    if (BrandBarHost._blancas.contains(ruta)) return AppColors.surface;
    return AppColors.surfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    if (BrandBarHost._sinBarra.contains(_ruta)) return widget.child;

    final ds = DsScale.of(context);
    final mq = MediaQuery.of(context);
    final conAcciones = BrandBarHost._conAcciones.contains(_ruta);

    // El nombre y el badge sólo se consultan cuando se van a ver: durante el
    // alta no hay sesión que preguntar.
    final nombre = conAcciones
        ? widget.modules
                .map((m) => m.getHeaderDisplayName(context))
                .firstWhere((n) => n != null && n.isNotEmpty,
                    orElse: () => null) ??
            ''
        : '';
    final sinLeer = conAcciones
        ? widget.modules
            .fold<int>(0, (acc, m) => acc + m.getHeaderBadgeCount(context))
        : 0;

    return Stack(
      children: [
        widget.child,
        // Franja del color de la pantalla, desde el borde físico hasta debajo
        // de la barra.
        //
        // El diseño deja la barra transparente porque su prototipo no scrollea
        // nunca; en la app sí —basta que el teclado empuje el contenido— y
        // entonces el botón de atrás de la pantalla se metía debajo del logo y
        // se veía cortado. La franja no cambia nada en reposo: es exactamente
        // el color que ya había ahí.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: mq.padding.top + ds.h(DsBrandBar.designHeight) + ds.h(6),
          child: IgnorePointer(
            child: ColoredBox(color: _fondo(_ruta)),
          ),
        ),
        Positioned(
          top: mq.padding.top,
          left: ds.w(16),
          right: ds.w(16),
          // La barra cuelga por encima del `Navigator`, o sea fuera de todo
          // `Material`: sin esto sus textos salen con el subrayado amarillo de
          // "falta un Material" que Flutter pinta como aviso de depuración.
          child: Material(
            type: MaterialType.transparency,
            child: DsBrandBar(
              initials: DsBrandBar.initialsOf(nombre),
              dark: BrandBarHost._oscuras.contains(_ruta),
              showActions: conAcciones,
              hasUnread: sinLeer > 0 && _ruta != '/notifications',
              onProfile: () => widget.router.go('/profile'),
              onNotifications: () => widget.router.go('/notifications'),
            ),
          ),
        ),
      ],
    );
  }
}
