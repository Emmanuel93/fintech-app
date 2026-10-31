import 'package:dio/dio.dart';

class ProfileMockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path != '/users/me') {
      handler.next(options);
      return;
    }
    Future.delayed(const Duration(milliseconds: 280), () {
      handler.resolve(Response(
        requestOptions: options,
        data: {
          'id': 'usr_emf_001',
          'fullName': 'Laura Méndez Soto',
          'firstName': 'Laura',
          'phone': '6673038098',
          'email': 'eramirezhdez@gmail.com',
          'curp': 'MESL930326MSLNTR04',
          'rfc': 'MESL930326JH8',
          'dateOfBirth': '1993-03-26',
          'state': 'Sinaloa',
          'memberSince': '2024-11-05',
          'kycStatus': 'Verificado',
          'creditLimit': 50000.0,
          // Expediente del alta — los mismos valores del prototipo (L1553).
          'gender': 'Masculino',
          'stateOfBirth': 'Sinaloa',
          'street': 'Av. Coyoacán',
          'exteriorNumber': '1435',
          'interiorNumber': '4B',
          'neighborhood': 'Del Valle Centro',
          'municipality': 'Benito Juárez',
          'city': 'Ciudad de México',
          'postalCode': '03100',
        },
        statusCode: 200,
      ));
    });
  }
}
