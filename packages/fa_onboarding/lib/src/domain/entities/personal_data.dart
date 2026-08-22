class PersonalData {
  const PersonalData({
    this.nombres = '',
    this.apellidoPaterno = '',
    this.apellidoMaterno = '',
    this.fechaNacimiento,
    this.curp = '',
    this.rfc = '',
    this.estadoNacimiento = '',
    this.genero = '',
    this.email = '',
    this.celular = '',
    // Ingreso mensual declarado — el prototipo lo pide en el grupo
    // "CONTACTO E INGRESO" (Journey L1095) y el motor de riesgo lo usa para
    // calcular capacidad de pago.
    this.ingresoMensual = '',
    // Domicilio estructurado (lo exige /kyc/submit del BFF)
    this.calle = '',
    this.numeroExterior = '',
    this.numeroInterior = '',
    this.colonia = '',
    this.municipio = '',
    this.ciudad = '',
    this.estado = '',
    this.codigoPostal = '',
  });

  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final DateTime? fechaNacimiento;
  final String curp;
  final String rfc;
  final String estadoNacimiento;
  final String genero;
  final String email;
  final String celular;
  final String ingresoMensual;

  final String calle;
  final String numeroExterior;
  final String numeroInterior;
  final String colonia;
  final String municipio;
  final String ciudad;
  final String estado;
  final String codigoPostal;

  String get nombreCompleto =>
      '$nombres $apellidoPaterno $apellidoMaterno'.trim();

  PersonalData copyWith({
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    DateTime? fechaNacimiento,
    String? curp,
    String? rfc,
    String? estadoNacimiento,
    String? genero,
    String? email,
    String? celular,
    String? ingresoMensual,
    String? calle,
    String? numeroExterior,
    String? numeroInterior,
    String? colonia,
    String? municipio,
    String? ciudad,
    String? estado,
    String? codigoPostal,
  }) =>
      PersonalData(
        nombres: nombres ?? this.nombres,
        apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
        apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
        curp: curp ?? this.curp,
        rfc: rfc ?? this.rfc,
        estadoNacimiento: estadoNacimiento ?? this.estadoNacimiento,
        genero: genero ?? this.genero,
        email: email ?? this.email,
        celular: celular ?? this.celular,
        ingresoMensual: ingresoMensual ?? this.ingresoMensual,
        calle: calle ?? this.calle,
        numeroExterior: numeroExterior ?? this.numeroExterior,
        numeroInterior: numeroInterior ?? this.numeroInterior,
        colonia: colonia ?? this.colonia,
        municipio: municipio ?? this.municipio,
        ciudad: ciudad ?? this.ciudad,
        estado: estado ?? this.estado,
        codigoPostal: codigoPostal ?? this.codigoPostal,
      );
}
