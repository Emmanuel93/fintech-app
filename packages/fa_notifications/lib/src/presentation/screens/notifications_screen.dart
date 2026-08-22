import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../providers/notification_provider.dart';
import '../../domain/entities/notification_item.dart';

/// Notificaciones — pantalla nueva del prototipo (Journey L1016–L1066,
/// datos en L1432–L1458).
///
/// Chips de filtro por categoría, agrupadas por día, con el punto ámbar de "sin
/// leer" y el icono/chip en el tono de la categoría. Al pie, el acceso a
/// preferencias de aviso.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Journey L1432. El índice 0 ("Todas") no filtra nada.
  static const _filters = ['Todas', 'Mi crédito', 'Oportunidades', 'Seguridad'];
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Siempre recarga al abrir: entre la última consulta (la del badge del
      // home) y este momento pueden haber llegado avisos — el desembolso que
      // se acaba de firmar, sin ir más lejos.
      context.read<NotificationProvider>().load();
    });
  }

  /// Cada tipo del dominio cae en una de las tres categorías que el diseño
  /// muestra como chip — y que son también los filtros.
  static _Category _categoryOf(NotificationType t) => switch (t) {
        NotificationType.security => _Category.seguridad,
        NotificationType.benefit ||
        NotificationType.marketing =>
          _Category.oportunidad,
        _ => _Category.credito,
      };

  static DsNotificationTone _toneOf(NotificationType t) => switch (t) {
        NotificationType.paymentDue => DsNotificationTone.warn,
        NotificationType.security => DsNotificationTone.bad,
        NotificationType.paymentReceived ||
        NotificationType.transferIn ||
        NotificationType.benefit =>
          DsNotificationTone.ok,
        _ => DsNotificationTone.info,
      };

  static IconData _iconOf(NotificationType t) => switch (t) {
        NotificationType.paymentDue => Icons.schedule_rounded,
        NotificationType.paymentReceived => Icons.check_rounded,
        NotificationType.security => Icons.shield_outlined,
        NotificationType.benefit => Icons.trending_up_rounded,
        NotificationType.marketing => Icons.local_offer_outlined,
        NotificationType.statement => Icons.description_outlined,
        NotificationType.transferIn => Icons.south_west_rounded,
        NotificationType.transferOut => Icons.north_east_rounded,
        NotificationType.withdrawal => Icons.payments_outlined,
        NotificationType.movement => Icons.swap_horiz_rounded,
      };

  /// "HOY" / "AYER" / "ESTA SEMANA" / la fecha — el prototipo agrupa por
  /// cercanía, no por fecha literal, que es como la gente recuerda un aviso.
  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'HOY';
    if (diff == 1) return 'AYER';
    if (diff < 7) return 'ESTA SEMANA';
    return DateFormat('d MMM yyyy', 'es_MX').format(d).toUpperCase();
  }

  static String _timeLabel(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return DateFormat('EEE d MMM', 'es_MX').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<NotificationProvider>();

    final visible = provider.items.where((n) {
      if (_filter == 0) return true;
      return _categoryOf(n.type).filterIndex == _filter;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Agrupadas por día, conservando el orden de llegada.
    final groups = <String, List<NotificationItem>>{};
    for (final n in visible) {
      groups.putIfAbsent(_dayLabel(n.date), () => []).add(n);
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              // Cabecera — Journey L1019–L1023.
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutterWide, ds.topGap, ds.gutterWide, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.go('/home')),
                    SizedBox(width: ds.w(12)),
                    Expanded(
                      child: Text('Notificaciones',
                          style: AppTextStyles.sectionTitle(
                              fontSize: ds.sp(19))),
                    ),
                    if (provider.unreadCount > 0)
                      GestureDetector(
                        onTap: provider.markAllRead,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                          child: Text('Marcar leídas',
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
              DsFilterChips(
                labels: _filters,
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),

              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : groups.isEmpty
                        ? _EmptyState(filtered: _filter != 0)
                        : ListView(
                            padding: EdgeInsets.fromLTRB(ds.gutterWide,
                                ds.h(16), ds.gutterWide, ds.bottomGap(24)),
                            children: [
                              for (final entry in groups.entries) ...[
                                Text(entry.key,
                                    style: AppTextStyles.captionLabel(
                                        fontSize: ds.sp(10))),
                                SizedBox(height: ds.h(9)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: ds.w(16)),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                        ds.r(AppRadii.cardSmall + 2)),
                                    border: Border.all(
                                        color: AppColors.outlineVariant),
                                  ),
                                  child: Column(
                                    children: [
                                      for (var i = 0;
                                          i < entry.value.length;
                                          i++)
                                        _tile(entry.value[i],
                                            isLast:
                                                i == entry.value.length - 1),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ds.h(16)),
                              ],
                              _PreferencesRow(
                                onTap: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Las preferencias de aviso llegan muy pronto.'))),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(NotificationItem n, {required bool isLast}) {
    return DsNotificationTile(
      icon: _iconOf(n.type),
      title: n.title,
      body: n.body,
      tag: _categoryOf(n.type).tag,
      time: _timeLabel(n.date),
      tone: _toneOf(n.type),
      unread: !n.isRead,
      isLast: isLast,
      onTap: () {
        if (!n.isRead) context.read<NotificationProvider>().markRead(n.id);
        final route = n.actionRoute;
        if (route != null && route.isNotEmpty) context.go(route);
      },
    );
  }
}

/// Las tres categorías que el diseño muestra como chip y como filtro.
enum _Category {
  credito('MI CRÉDITO', 1),
  oportunidad('OPORTUNIDAD', 2),
  seguridad('SEGURIDAD', 3);

  const _Category(this.tag, this.filterIndex);
  final String tag;
  final int filterIndex;
}

/// Acceso a preferencias — Journey L1055–L1064.
class _PreferencesRow extends StatelessWidget {
  const _PreferencesRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        child: Container(
          padding: EdgeInsets.all(ds.w(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: ds.w(38),
                height: ds.w(38),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(ds.r(11)),
                ),
                child: Icon(Icons.settings_outlined,
                    size: ds.sp(18), color: AppColors.primary),
              ),
              SizedBox(width: ds.w(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elige qué te avisamos',
                        style: AppTextStyles.body(
                          fontSize: ds.sp(13.5),
                          weight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ).copyWith(height: 1.25)),
                    SizedBox(height: ds.h(5)),
                    Text('Pagos, ofertas y avisos de seguridad, por separado.',
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11.5),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: ds.sp(16), color: AppColors.disabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ds.gutterWide),
        child: DsEmptyStateCard(
          icon: Icons.notifications_none_rounded,
          title: filtered ? 'Nada en esta categoría' : 'Sin novedades',
          message: filtered
              ? 'Prueba con otro filtro: puede que el aviso que buscas esté en otra categoría.'
              : 'Aquí te avisamos de tus pagos, de las líneas que se abren para ti y de cualquier movimiento de seguridad.',
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: ds.w(38),
          height: ds.w(38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(12)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: ds.sp(18), color: AppColors.onSurface),
        ),
      ),
    );
  }
}
