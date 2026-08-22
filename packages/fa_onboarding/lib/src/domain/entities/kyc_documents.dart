import 'document_file.dart';

/// Los cuatro documentos que pide el alta, en el orden exacto del prototipo
/// (`Kredius Journey.dc.html` L1107–L1111).
///
/// El orden importa: es el orden en que se muestran y el que determina cuál es
/// "el siguiente pendiente".
enum KycDocumentKind {
  ineFrente(
    label: 'INE · frente',
    hint: 'Foto nítida, sin reflejos',
    required: true,
  ),
  ineReverso(
    label: 'INE · reverso',
    hint: 'Que se lea el código de barras',
    required: true,
  ),
  selfie(
    label: 'Selfie de vida',
    hint: 'Prueba de vida con parpadeo',
    required: true,
  ),
  comprobanteDomicilio(
    label: 'Comprobante de domicilio',
    hint: 'No mayor a 3 meses',
    required: true,
  );

  const KycDocumentKind({
    required this.label,
    required this.hint,
    required this.required,
  });

  final String label;
  final String hint;

  /// Si es obligatorio para poder continuar a la pestaña de Datos.
  final bool required;

  /// Los dos lados del INE son los únicos que alimentan el OCR.
  bool get feedsOcr =>
      this == KycDocumentKind.ineFrente || this == KycDocumentKind.ineReverso;
}

/// Documentos capturados en el alta.
///
/// Sustituye a la antigua `IneImages`, que sólo contemplaba frente y reverso:
/// el diseño pide además selfie de vida y comprobante de domicilio, y los pide
/// **antes** de los datos, porque el OCR del INE es lo que prellena el
/// formulario.
class KycDocuments {
  const KycDocuments({this.files = const {}});

  final Map<KycDocumentKind, DocumentFile> files;

  DocumentFile? operator [](KycDocumentKind kind) => files[kind];

  bool has(KycDocumentKind kind) => files.containsKey(kind);

  /// Frente + reverso capturados: ya se puede llamar al OCR.
  bool get canRunOcr =>
      has(KycDocumentKind.ineFrente) && has(KycDocumentKind.ineReverso);

  /// Todos los obligatorios capturados: ya se puede pasar a Datos.
  bool get isComplete => KycDocumentKind.values
      .where((k) => k.required)
      .every((k) => files.containsKey(k));

  /// Primer documento obligatorio que falta — para enfocar la captura.
  KycDocumentKind? get nextPending {
    for (final k in KycDocumentKind.values) {
      if (k.required && !files.containsKey(k)) return k;
    }
    return null;
  }

  int get capturedCount => files.length;

  KycDocuments withDocument(KycDocumentKind kind, DocumentFile file) =>
      KycDocuments(files: {...files, kind: file});

  KycDocuments without(KycDocumentKind kind) =>
      KycDocuments(files: {...files}..remove(kind));
}
