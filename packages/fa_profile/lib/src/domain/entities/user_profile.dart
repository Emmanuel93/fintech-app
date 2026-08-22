class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.curp,
    required this.rfc,
    required this.memberSince,
    required this.kycStatus,
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

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String curp;
  final String rfc;
  final DateTime memberSince;
  final DateTime dateOfBirth;
  final String state;
  final String kycStatus;
  final double? creditLimit;

  // ── Expediente del alta ───────────────────────────────────────────────────
  // Lo captura la persona en el alta y lo guarda origination; el perfil lo
  // enseña completo. Van con default vacío porque un backend que todavía no los
  // exponga no debe romper la pantalla: los renglones sin valor no se pintan.
  final String gender;
  final String stateOfBirth;
  final String street, exteriorNumber, interiorNumber;
  final String neighborhood, municipality, city, postalCode;

  /// "Av. Coyoacán 1435, int. 4B" — vacío si no hay calle.
  String get streetLine {
    if (street.isEmpty) return '';
    final ext = exteriorNumber.isEmpty ? '' : ' $exteriorNumber';
    final int_ = interiorNumber.isEmpty ? '' : ', int. $interiorNumber';
    return '$street$ext$int_';
  }

  /// "Culiacán, Culiacán" — colapsa si municipio y ciudad coinciden.
  String get cityLine {
    if (municipality.isEmpty) return city;
    if (city.isEmpty || city == municipality) return municipality;
    return '$municipality, $city';
  }

  /// "Sinaloa · 80060".
  String get stateLine {
    if (state.isEmpty) return postalCode;
    if (postalCode.isEmpty) return state;
    return '$state · $postalCode';
  }

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
