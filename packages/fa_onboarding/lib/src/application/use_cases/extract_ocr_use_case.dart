import '../../domain/entities/document_file.dart';
import '../../domain/entities/ocr_extracted_data.dart';
import '../../domain/ports/i_ocr_repository.dart';

class ExtractOcrUseCase {
  const ExtractOcrUseCase(this._repository);
  final IOcrRepository _repository;

  Future<OcrExtractedData> call({
    required DocumentFile frente,
    required DocumentFile reverso,
  }) =>
      _repository.extractFromIne(frente: frente, reverso: reverso);
}
