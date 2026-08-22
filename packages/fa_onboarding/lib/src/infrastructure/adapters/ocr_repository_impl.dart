import 'package:fa_core/fa_core.dart';
import '../../domain/entities/document_file.dart';
import '../../domain/entities/ocr_extracted_data.dart';
import '../../domain/ports/i_ocr_repository.dart';
import '../dtos/ocr_dto.dart';

class OcrRepositoryImpl implements IOcrRepository {
  OcrRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<OcrExtractedData> extractFromIne({
    required DocumentFile frente,
    required DocumentFile reverso,
  }) async {
    final json = await _client.post('/ocr/extract', body: {
      'frente': frente.fileName,
      'reverso': reverso.fileName,
    });
    return OcrDto.fromJson(json).toDomain();
  }
}
