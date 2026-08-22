class OcrExtractedData {
  const OcrExtractedData({
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

  static OcrExtractedData get mock => const OcrExtractedData(
        nombres: 'CARLOS ANTONIO',
        apellidoPaterno: 'RAMÍREZ',
        apellidoMaterno: 'TORRES',
        curp: 'RATC850320HDFMRL09',
        fechaNacimiento: '20/03/1985',
        domicilio:
            'AV. INSURGENTES SUR 1602, COL. CRÉDITO CONSTRUCTOR, CDMX 03940',
        clave: '0850320DF0001234',
        vigencia: '2031',
        genero: 'M',
        estadoNacimiento: 'Ciudad de México',
      );
}
