import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

/// Mi perfil — Journey App L951–L982.
///
/// El diseño lo resuelve como el tab 4 del home: fondo claro, una barra simple
/// con vuelta al inicio, y el expediente en **grupos de campos** de sólo
/// lectura, cada uno con el sello de dónde salió el dato (INE · OCR, VALIDADO,
/// OTP VERIFICADO). Abajo, los contratos vigentes.
///
/// Reemplaza el héroe azul a pantalla completa del lenguaje anterior. No es
/// sólo estética: en el diseño esta pantalla es un expediente que se consulta,
/// y el azul de marca está reservado para el dinero —la línea, los créditos— y
/// para los momentos de desenlace del alta.
///
/// Los renglones sin valor **no se pintan**. El perfil se arma con dos fuentes
/// (party e origination) y si la segunda no respondió, es más honesto enseñar
/// menos que enseñar etiquetas con la nada al lado.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        bottom: false,
        child: DsResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutterWide, ds.topGap, ds.gutterWide, 0),
                child: DsTopBar(
                  title: 'Mi perfil',
                  onBack: () => context.go('/home'),
                ),
              ),
              Expanded(
                child: profile == null
                    ? Center(
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.primary)
                            : _SinExpediente(
                                onRetry: () =>
                                    context.read<ProfileProvider>().reload(),
                              ),
                      )
                    : _Expediente(profile: profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El expediente en grupos, tal cual el diseño (L957–L980).
class _Expediente extends StatelessWidget {
  const _Expediente({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final fecha = DateFormat('dd/MM/yyyy', 'es_MX');

    final grupos = <_Grupo>[
      _Grupo('IDENTIDAD', 'INE · OCR', [
        ('Nombre completo', profile.fullName.comoNombrePropio),
        ('Fecha de nacimiento', fecha.format(profile.dateOfBirth)),
        ('Género', profile.gender),
        ('Estado de nacimiento', profile.stateOfBirth),
      ]),
      _Grupo('CLAVES FISCALES', 'VALIDADO', [
        ('CURP', profile.curp),
        ('RFC', profile.rfc),
      ]),
      _Grupo('DOMICILIO', 'CP VALIDADO', [
        ('Calle y número', profile.streetLine),
        ('Colonia', profile.neighborhood),
        ('Municipio / Ciudad', profile.cityLine),
        ('Estado y C.P.', profile.stateLine),
      ]),
      _Grupo('CONTACTO', 'OTP VERIFICADO', [
        ('Celular', profile.phone),
        ('Email', profile.email),
        ('Cliente desde', fecha.format(profile.memberSince)),
      ]),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
          ds.gutterWide, ds.h(18), ds.gutterWide, ds.bottomGap(26)),
      children: [
        for (final g in grupos)
          if (g.conDatos) ...[
            _GrupoDeCampos(grupo: g),
            SizedBox(height: ds.h(16)),
          ],
        _Contratos(profile: profile),
      ],
    );
  }
}

/// Un grupo del expediente: título, sello de origen y la tarjeta de renglones.
class _GrupoDeCampos extends StatelessWidget {
  const _GrupoDeCampos({required this.grupo});

  final _Grupo grupo;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final filas = grupo.filasConValor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(grupo.titulo,
                  style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
            ),
            _SelloDeOrigen(texto: grupo.origen),
          ],
        ),
        SizedBox(height: ds.h(9)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: ds.w(16)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(14)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < filas.length; i++)
                Container(
                  padding: EdgeInsets.symmetric(vertical: ds.h(12)),
                  decoration: i == filas.length - 1
                      ? null
                      : const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.divider),
                          ),
                        ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: ds.w(118),
                        child: Text(filas[i].$1,
                            style: AppTextStyles.body(
                              fontSize: ds.sp(12.5),
                              color: AppColors.disabled,
                            ).copyWith(height: 1.3)),
                      ),
                      SizedBox(width: ds.w(12)),
                      Expanded(
                        child: Text(filas[i].$2,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.body(
                              fontSize: ds.sp(13.5),
                              weight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ).copyWith(height: 1.35)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El sello verde que dice de dónde salió el dato (L960).
class _SelloDeOrigen extends StatelessWidget {
  const _SelloDeOrigen({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: ds.w(8), vertical: ds.h(4)),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(texto,
          style: AppTextStyles.body(
            fontSize: ds.sp(9),
            weight: FontWeight.w600,
            color: AppColors.onSecondaryContainer,
          ).copyWith(height: 1.0, letterSpacing: 0.08 * 9)),
    );
  }
}

/// Contratos vigentes — Journey L973–L980.
///
/// La lista real la sirve credit-portfolio y todavía no llega por el BFF, así
/// que de momento se dice eso en vez de inventar filas: un contrato es un
/// documento con efectos legales y enseñar uno que no existe es peor que no
/// enseñar ninguno.
class _Contratos extends StatelessWidget {
  const _Contratos({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CONTRATOS VIGENTES',
            style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
        SizedBox(height: ds.h(9)),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: ds.w(16), vertical: ds.h(16)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(14)),
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
                  borderRadius: BorderRadius.circular(ds.r(10)),
                ),
                child: Text('PDF',
                    style: AppTextStyles.cardTitle(
                            fontSize: ds.sp(10), color: AppColors.primary)
                        .copyWith(height: 1.0)),
              ),
              SizedBox(width: ds.w(12)),
              Expanded(
                child: Text(
                  'Los encuentras en el detalle de cada crédito, junto con su '
                  'tabla de pagos.',
                  style: AppTextStyles.body(fontSize: ds.sp(12.5))
                      .copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sin perfil: la petición falló o todavía no hay expediente.
class _SinExpediente extends StatelessWidget {
  const _SinExpediente({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ds.gutterWide),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined,
              size: ds.sp(40), color: AppColors.disabled),
          SizedBox(height: ds.h(14)),
          Text('No pudimos traer tu expediente',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle(fontSize: ds.sp(17))),
          SizedBox(height: ds.h(8)),
          Text('Revisa tu conexión e inténtalo otra vez.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: ds.sp(13))),
          SizedBox(height: ds.h(18)),
          DsButton(label: 'Reintentar', onPressed: onRetry),
        ],
      ),
    );
  }
}

/// Un grupo del expediente y sus renglones.
class _Grupo {
  const _Grupo(this.titulo, this.origen, this.filas);

  final String titulo;
  final String origen;
  final List<(String, String)> filas;

  /// Sólo los renglones que tienen algo que decir.
  List<(String, String)> get filasConValor =>
      filas.where((f) => f.$2.trim().isNotEmpty).toList();

  bool get conDatos => filasConValor.isNotEmpty;
}
