import '../../domain/entities/user_profile.dart';

class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.curp,
    required this.rfc,
    required this.kycStatus,
    required this.memberSince,
    required this.dateOfBirth,
    required this.state,
    this.creditLimit,
    this.gender = '',
    this.stateOfBirth = '',
    this.street = '',
    this.exteriorNumber = '',
    this.interiorNumber = '',
    this.neighborhood = '',
    this.municipality = '',
    this.city = '',
    this.postalCode = '',
  });

  final String id, fullName, phone, email, curp, rfc, kycStatus;
  final String memberSince, dateOfBirth, state;
  final double? creditLimit;
  final String gender, stateOfBirth;
  final String street, exteriorNumber, interiorNumber;
  final String neighborhood, municipality, city, postalCode;

  // Tolerante a respuestas parciales: el BFF junta party (identidad) con el
  // expediente de origination (domicilio, género, contacto). Si esa segunda
  // consulta falló, esos campos llegan vacíos y la pantalla los omite en vez
  // de pintar renglones huecos.
  factory ProfileDto.fromJson(Map<String, dynamic> j) => ProfileDto(
        id: j['id'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        curp: j['curp'] as String? ?? '',
        rfc: j['rfc'] as String? ?? '',
        kycStatus: j['kycStatus'] as String? ?? '',
        memberSince: j['memberSince'] as String? ?? '1900-01-01',
        dateOfBirth: j['dateOfBirth'] as String? ?? '1900-01-01',
        state: j['state'] as String? ?? '',
        creditLimit: (j['creditLimit'] as num?)?.toDouble(),
        gender: j['gender'] as String? ?? '',
        stateOfBirth: j['stateOfBirth'] as String? ?? '',
        street: j['street'] as String? ?? '',
        exteriorNumber: j['exteriorNumber'] as String? ?? '',
        interiorNumber: j['interiorNumber'] as String? ?? '',
        neighborhood: j['neighborhood'] as String? ?? '',
        municipality: j['municipality'] as String? ?? '',
        city: j['city'] as String? ?? '',
        postalCode: j['postalCode'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'fullName': fullName, 'phone': phone, 'email': email,
        'curp': curp, 'rfc': rfc, 'kycStatus': kycStatus,
        'memberSince': memberSince, 'dateOfBirth': dateOfBirth,
        'state': state, 'creditLimit': creditLimit,
        'gender': gender, 'stateOfBirth': stateOfBirth,
        'street': street, 'exteriorNumber': exteriorNumber,
        'interiorNumber': interiorNumber, 'neighborhood': neighborhood,
        'municipality': municipality, 'city': city, 'postalCode': postalCode,
      };

  UserProfile toDomain() => UserProfile(
        id: id,
        fullName: fullName,
        phone: phone,
        email: email,
        curp: curp,
        rfc: rfc,
        kycStatus: kycStatus,
        memberSince: DateTime.parse(memberSince),
        dateOfBirth: DateTime.parse(dateOfBirth),
        state: state,
        creditLimit: creditLimit,
        gender: gender,
        stateOfBirth: stateOfBirth,
        street: street,
        exteriorNumber: exteriorNumber,
        interiorNumber: interiorNumber,
        neighborhood: neighborhood,
        municipality: municipality,
        city: city,
        postalCode: postalCode,
      );
}
