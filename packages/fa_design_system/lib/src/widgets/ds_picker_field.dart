import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import 'ds_translucent_field.dart' show dsFieldKey, DsFormField;

/// Selector de una opción de una lista larga.
///
/// Sustituye a `DropdownButtonFormField` en los catálogos grandes — los 32
/// estados de la república, por ejemplo. Con un menú desplegable acotado a
/// ~40% de la pantalla caben siete opciones: llegar a Sinaloa (#25) o Sonora
/// (#26) exige arrastrar a ciegas dentro de un menú flotante, y en la práctica
/// la cola de la lista quedaba fuera del alcance.
///
/// Aquí la lista se abre en una hoja de alto completo **con buscador**: se
/// escribe "son" y aparece Sonora. La búsqueda ignora acentos y mayúsculas,
/// porque nadie escribe "Michoacán" con tilde en un teclado de teléfono.
class DsPickerField extends StatelessWidget {
  const DsPickerField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = 'Seleccionar',
    this.sheetTitle,
    this.searchHint = 'Buscar',
    this.showLabel = true,
    this.validator,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String hint;

  /// Encabezado de la hoja. Por defecto, la etiqueta del campo.
  final String? sheetTitle;
  final String searchHint;
  final bool showLabel;
  final String? Function(String?)? validator;

  /// "Michoacán" → "michoacan". Para que la búsqueda no dependa de acentos.
  static String normalize(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet(
        title: sheetTitle ?? label,
        options: options,
        selected: value,
        searchHint: searchHint,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final hasValue = value != null && value!.isNotEmpty;

    return FormField<String>(
      key: ValueKey(dsFieldKey(label)),
      initialValue: value,
      validator: validator,
      builder: (field) {
        // El FormField guarda su propia copia; se sincroniza con la de fuera.
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            field.didChange(value);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel) ...[
              Text(label,
                  style: AppTextStyles.fieldLabel(fontSize: ds.sp(11.5))),
              SizedBox(height: ds.h(7)),
            ],
            Semantics(
              button: true,
              label: '$label. ${hasValue ? value : hint}',
              child: InkWell(
                onTap: () => _open(context),
                borderRadius: BorderRadius.circular(ds.r(12)),
                child: Container(
                  height: ds.h(48),
                  padding: EdgeInsets.symmetric(horizontal: ds.w(14)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(ds.r(12)),
                    border: Border.all(
                      color: field.hasError
                          ? AppColors.error
                          : hasValue
                              ? DsFormField.filledBorder
                              : AppColors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasValue ? value! : hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.inputText(
                            fontSize: ds.sp(14.5),
                            color: hasValue
                                ? AppColors.onSurface
                                : AppColors.disabled,
                          ),
                        ),
                      ),
                      Icon(Icons.expand_more_rounded,
                          size: ds.sp(20), color: AppColors.disabled),
                    ],
                  ),
                ),
              ),
            ),
            if (field.hasError) ...[
              SizedBox(height: ds.h(6)),
              Text(field.errorText!,
                  style: AppTextStyles.body(
                      fontSize: ds.sp(11.5), color: AppColors.error)),
            ],
          ],
        );
      },
    );
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchHint,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final String searchHint;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';

  /// Alto exacto de cada fila.
  ///
  /// Es fijo a propósito: con `itemExtent` la lista sabe dónde está cada opción
  /// sin construirla, así que saltar a la #25 es aritmética y no un arrastre a
  /// ciegas. Y compacto, para que quepan ~16 de 32 en pantalla en vez de 12.
  static const _rowExtent = 46.0;

  double get _extent => DsScale.of(context).h(_rowExtent);

  @override
  void initState() {
    super.initState();
    // Reabrir el selector con "Sonora" puesto y aterrizar en la A es perder de
    // vista lo que ya se había respondido. Se abre en lo elegido.
    final at = widget.options.indexOf(widget.selected ?? '');
    if (at <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(at));
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Deja la opción [index] cerca del tercio superior: pegada al borde no se ve
  /// que hay lista antes, y centrada desperdicia media pantalla.
  void _jumpTo(int index) {
    if (!_scroll.hasClients) return;
    final target = index * _extent - _extent * 2;
    _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  List<String> get _visible {
    final q = DsPickerField.normalize(_query.trim());
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => DsPickerField.normalize(o).contains(q))
        .toList();
  }

  /// Inicial → índice de la primera opción que empieza con ella. Es lo que
  /// convierte "llegar a Sinaloa" en un toque en la S.
  Map<String, int> _indexByLetter(List<String> options) {
    final map = <String, int>{};
    for (var i = 0; i < options.length; i++) {
      final letter =
          DsPickerField.normalize(options[i]).substring(0, 1).toUpperCase();
      map.putIfAbsent(letter, () => i);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final media = MediaQuery.of(context);
    final visible = _visible;
    final letters = _indexByLetter(visible);

    // El alto se toma de la pantalla completa y **no** se le resta el teclado:
    // restarlo encogía la hoja hasta dejar la lista en dos renglones en cuanto
    // se tocaba el buscador. El teclado tapa la parte baja y la lista sigue
    // scrolleando por debajo, con padding suficiente para alcanzar el final.
    final sheetHeight = media.size.height * 0.92;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: ds.h(10)),
          Container(
            width: ds.w(40),
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: ds.h(14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ds.gutter),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style:
                              AppTextStyles.sectionTitle(fontSize: ds.sp(18))),
                      SizedBox(height: ds.h(3)),
                      // Decir cuántas hay evita la duda de si la lista está
                      // completa o cortada.
                      Text(
                        _query.isEmpty
                            ? '${widget.options.length} opciones'
                            : '${visible.length} de ${widget.options.length}',
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11.5),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.0),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Cerrar',
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(ds.w(4)),
                      child: Icon(Icons.close_rounded,
                          size: ds.sp(20), color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ds.h(12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ds.gutter),
            child: TextField(
              controller: _search,
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.inputText(fontSize: ds.sp(14.5)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                hintText: widget.searchHint,
                hintStyle: AppTextStyles.inputText(
                    fontSize: ds.sp(14.5), color: AppColors.disabled),
                prefixIcon: Icon(Icons.search_rounded,
                    size: ds.sp(20), color: AppColors.disabled),
                suffixIcon: _query.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.close_rounded,
                            size: ds.sp(18), color: AppColors.disabled),
                      ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: ds.h(14), horizontal: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ds.r(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: ds.h(6)),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text('Sin resultados para "$_query"',
                        style: AppTextStyles.body(fontSize: ds.sp(13.5))),
                  )
                : Row(
                    children: [
                      Expanded(
                        // Barra siempre visible: en una lista de 32 el usuario
                        // tiene que **ver** que hay más abajo, no deducirlo.
                        child: Scrollbar(
                          controller: _scroll,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scroll,
                            itemExtent: _extent,
                            padding: EdgeInsets.only(
                              left: ds.gutter,
                              right: ds.w(6),
                              // Con el teclado abierto la lista sigue viva por
                              // debajo: este relleno deja alcanzar la última
                              // opción en vez de dejarla tapada para siempre.
                              bottom:
                                  media.viewInsets.bottom + ds.bottomGap(16),
                            ),
                            itemCount: visible.length,
                            itemBuilder: (_, i) => _OptionRow(
                              label: visible[i],
                              selected: visible[i] == widget.selected,
                              onTap: () => Navigator.pop(context, visible[i]),
                            ),
                          ),
                        ),
                      ),
                      // Índice alfabético: llegar a Sinaloa es tocar la S.
                      if (_query.isEmpty && letters.length > 4)
                        _AlphabetRail(
                          letters: letters,
                          onPick: _jumpTo,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fila de opción.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ds.w(12)),
        margin: EdgeInsets.symmetric(vertical: ds.h(2)),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    fontSize: ds.sp(14.5),
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.onSurface,
                  ).copyWith(height: 1.0)),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  size: ds.sp(18), color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Índice alfabético lateral, como el de Contactos.
///
/// Es lo que hace que una lista de 32 no dependa de arrastrar: se toca la letra
/// y la lista salta. Arrastrar el dedo por la columna recorre el abecedario.
class _AlphabetRail extends StatelessWidget {
  const _AlphabetRail({required this.letters, required this.onPick});

  final Map<String, int> letters;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final keys = letters.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        void pickAt(Offset local) {
          final i = (local.dy / constraints.maxHeight * keys.length)
              .floor()
              .clamp(0, keys.length - 1);
          onPick(letters[keys[i]]!);
        }

        return Semantics(
          label: 'Índice alfabético',
          child: GestureDetector(
            onTapDown: (d) => pickAt(d.localPosition),
            onVerticalDragUpdate: (d) => pickAt(d.localPosition),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: ds.w(26),
              padding: EdgeInsets.symmetric(vertical: ds.h(4)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final k in keys)
                    Text(k,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(10),
                          weight: FontWeight.w600,
                          color: AppColors.primary,
                        ).copyWith(height: 1.0)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
