import '../../domain/entities/ocr_extracted_data.dart';

class OcrDto {
  const OcrDto({
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.curp,
    required this.fechaNacimiento,
    required this.domicilio,
    required this.clave,
    required this.vigencia,
    required this.genero,
    required this.estadoNacimiento,
  });

  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String curp;
  final String fechaNacimiento;
  final String domicilio;
  final String clave;
  final String vigencia;
  final String genero;
  final String estadoNacimiento;

  factory OcrDto.fromJson(Map<String, dynamic> j) => OcrDto(
        nombres: j['nombres'] as String? ?? '',
        apellidoPaterno: j['apellidoPaterno'] as String? ?? '',
        apellidoMaterno: j['apellidoMaterno'] as String? ?? '',
        curp: j['curp'] as String? ?? '',
        fechaNacimiento: j['fechaNacimiento'] as String? ?? '',
        domicilio: j['domicilio'] as String? ?? '',
        clave: j['clave'] as String? ?? '',
        vigencia: j['vigencia'] as String? ?? '',
        genero: j['genero'] as String? ?? '',
        estadoNacimiento: j['estadoNacimiento'] as String? ?? '',
      );

  OcrExtractedData toDomain() => OcrExtractedData(
        nombres: nombres,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        curp: curp,
        fechaNacimiento: fechaNacimiento,
        domicilio: domicilio,
        clave: clave,
        vigencia: vigencia,
        genero: genero,
        estadoNacimiento: estadoNacimiento,
      );
}
