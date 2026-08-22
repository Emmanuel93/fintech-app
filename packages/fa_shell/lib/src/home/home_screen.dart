import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'package:fa_core/fa_core.dart';

/// Home — pantalla 11 del prototipo (Journey L568–L805).
///
/// Sigue completamente desacoplado: no importa ningún módulo, sólo conoce
/// [IModule]. Cada módulo aporta su card del tab "Inicio" vía
/// [IModule.buildHomeCard] y, opcionalmente, un tab propio con
/// [IModule.ownedTab] + [IModule.buildTabScreen].
///
/// Lo que cambió respecto de la versión anterior es el envoltorio, para que
/// coincida con el diseño: header **claro** con sólo "Hola, {nombre}" (L707) y
/// bottom nav propio (L791–L804) en vez del `NavigationBar` de Material.
/// El avatar y la campana ya no están aquí: subieron a la barra de marca
/// global, que el diseño monta sobre todas las pantallas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.modules});

  final List<IModule> modules;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final m in widget.modules) {
        m.initHome(context);
      }
    });
  }

  Future<void> _refresh() async {
    for (final m in widget.modules) {
      m.initHome(context);
    }
    // Pequeña espera para que el indicador de refresco sea visible.
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Los tabs que hay **ahora**, en el orden del diseño: Inicio siempre, luego
  /// los que aporten los módulos visibles y, si no hay línea de colocación, el
  /// atajo a Oportunidades en el último lugar (Journey App L1701–L1708).
  List<_NavEntry> _entries(BuildContext context) {
    final entries = <_NavEntry>[
      const _NavEntry(icon: Icons.home_outlined, label: 'Inicio'),
    ];

    for (final tab in HomeTab.values) {
      for (final m in widget.modules) {
        if (!m.ownedTabs.contains(tab) || !m.areTabsVisible(context)) continue;
        final meta = _tabMeta[tab]!;
        entries.add(_NavEntry(
          icon: meta.icon,
          label: meta.label,
          builder: (ctx) => m.buildTabScreen(ctx, tab),
        ));
        break;
      }
    }

    // Quien ya coloca no necesita el catálogo en el nav: su acción principal es
    // enviar préstamos, no contratar otro producto.
    final colocando = entries.any((e) => e.label == 'Colocaciones');
    if (!colocando) {
      entries.add(const _NavEntry(
        icon: Icons.star_outline_rounded,
        label: 'Oportunidades',
        route: '/credit/apply',
      ));
    }
    return entries;
  }

  static const _tabMeta = <HomeTab, ({IconData icon, String label})>{
    HomeTab.movimientos:
        (icon: Icons.swap_horiz_rounded, label: 'Movimientos'),
    HomeTab.colocaciones: (icon: Icons.hub_outlined, label: 'Colocaciones'),
    HomeTab.beneficiarios:
        (icon: Icons.how_to_reg_outlined, label: 'Beneficiarios'),
  };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;

    final firstName = widget.modules
            .map((m) => m.getHeaderDisplayName(context))
            .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null) ??
        '';

    final entries = _entries(context);
    // El nav cambia de forma cuando aparece la línea de distribuidor. Si el tab
    // activo desaparece en ese cambio, quedarse en su índice mostraría otra
    // pantalla sin que el usuario haya tocado nada.
    final tab = _tab < entries.length ? _tab : 0;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        bottom: false,
        child: DsResponsiveBody(
          child: Column(
            children: [
              _Header(
                firstName: firstName,
                onProfile: () => context.go('/profile'),
              ),
              Expanded(
                child: IndexedStack(
                  index: tab,
                  children: [
                    for (final (i, entry) in entries.indexed)
                      if (i == 0)
                        _InicioTab(
                            modules: widget.modules, onRefresh: _refresh)
                      else
                        entry.builder?.call(context) ?? const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        entries: entries,
        index: tab,
        // Los que llevan `route` no son pestañas: navegan a pantalla completa,
        // igual que `goOffers` en el prototipo (Journey App L1711).
        onChanged: (i) {
          final route = entries[i].route;
          if (route != null) {
            context.go(route);
          } else {
            setState(() => _tab = i);
          }
        },
        bottomInset: ds.padding.bottom,
      ),
    );
  }
}

/// Un botón del bottom nav. O construye una pestaña ([builder]) o navega
/// ([route]) — nunca las dos.
class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    this.builder,
    this.route,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder? builder;
  final String? route;
}

// ─── Tab "Inicio" ─────────────────────────────────────────────────────────────

class _InicioTab extends StatelessWidget {
  const _InicioTab({required this.modules, required this.onRefresh});

  final List<IModule> modules;
  final Future<void> Function() onRefresh;

  /// Los módulos por prelación de card (línea de distribuidor → créditos
  /// propios → el resto).
  ///
  /// El desempate por índice es explícito porque `List.sort` de Dart no promete
  /// ser estable: sin él, dos módulos con la misma prelación podrían alternarse
  /// entre builds y el home cambiaría de orden solo.
  List<IModule> get _ordenadas {
    final indexado = modules.indexed.toList();
    indexado.sort((a, b) {
      final porPrelacion =
          a.$2.homeCardOrder.compareTo(b.$2.homeCardOrder);
      return porPrelacion != 0 ? porPrelacion : a.$1.compareTo(b.$1);
    });
    return [for (final (_, m) in indexado) m];
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: ds.h(18), bottom: ds.h(24)),
        child: Column(
          children: [
            // Cada módulo aporta su propia card. El shell no sabe qué hay
            // dentro: sólo respeta la prelación que cada uno declara, para que
            // el orden no dependa de en qué renglón quedó en `ShellInjection`.
            for (final module in _ordenadas)
              if (module.buildHomeCard(context) case final card?) card,
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

/// Journey L707–L712: "Hola," + nombre 21/800 con chevron a perfil.
///
/// Ya no lleva campana ni avatar: el rediseño los subió a la barra de marca
/// global ([DsBrandBar]), que está sobre esta pantalla y sobre todas las demás.
/// Dejarlos aquí los duplicaría a dos centímetros de distancia.
class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.onProfile});

  final String firstName;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    // El nombre llega en mayúsculas del expediente (así lo guarda la INE) y
    // "Hola, EMMANUEL" se lee como un regaño. Se normaliza al mostrarlo, no en
    // el dato: el expediente tiene que seguir diciendo lo que dice la INE.
    final displayName = firstName.isEmpty
        ? 'que gusto verte'
        : firstName.comoNombrePropio;

    return Padding(
      // El diseño abre el home en `padding-top:96px` (L706): la barra de marca
      // vive justo encima y el saludo empieza debajo de ella.
      padding: EdgeInsets.fromLTRB(
          ds.gutterWide, ds.topGap, ds.gutterWide, ds.h(4)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onProfile,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Hola,',
                      style: AppTextStyles.body(
                        fontSize: ds.sp(12.5),
                        weight: FontWeight.w500,
                        color: AppColors.disabled,
                      ).copyWith(height: 1.0)),
                  SizedBox(height: ds.h(8)),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heroNumber(ds.sp(21),
                              color: AppColors.onSurface),
                        ),
                      ),
                      SizedBox(width: ds.w(7)),
                      Icon(Icons.chevron_right_rounded,
                          size: ds.sp(18), color: AppColors.disabled),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

/// Journey App L971–L978, estilo del tab en L1712: 58px de alto, radio 14,
/// activo con fondo `surfaceVariant` y color `primary`; inactivo `#9AA2B1`.
///
/// El número de botones no es fijo: son 3 para quien pide para sí y 4 para
/// quien tiene línea de colocación.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.entries,
    required this.index,
    required this.onChanged,
    required this.bottomInset,
  });

  final List<_NavEntry> entries;
  final int index;
  final ValueChanged<int> onChanged;
  final double bottomInset;

  static const _inactive = AppColors.navInactive;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.navBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
        ds.w(12),
        ds.h(10),
        ds.w(12),
        // Respeta el home indicator; si no hay, cae al padding del diseño.
        bottomInset > 0 ? bottomInset : ds.h(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) SizedBox(width: ds.w(4)),
            Expanded(
              child: _NavTab(
                icon: entries[i].icon,
                label: entries[i].label,
                active: i == index,
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final color = active ? AppColors.primary : _BottomNav._inactive;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: KrediusMotion.tab,
          curve: KrediusMotion.ease,
          height: ds.h(58),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(ds.r(14)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: ds.sp(21), color: color),
              SizedBox(height: ds.h(6)),
              // "Movimientos" es largo: en pantallas angostas se reduce antes
              // que truncarse a "Movimien…".
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: AppTextStyles.navLabel(
                        fontSize: ds.sp(10.5), color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
