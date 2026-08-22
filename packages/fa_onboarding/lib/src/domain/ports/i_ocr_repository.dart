import '../entities/document_file.dart';
import '../entities/ocr_extracted_data.dart';

abstract interface class IOcrRepository {
  Future<OcrExtractedData> extractFromIne({
    required DocumentFile frente,
    required DocumentFile reverso,
  });
}
