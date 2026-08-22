import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fa_core/fa_core.dart';
import 'src/application/use_cases/send_otp_use_case.dart';
import 'src/application/use_cases/verify_otp_use_case.dart';
import 'src/application/use_cases/extract_ocr_use_case.dart';
import 'src/application/use_cases/submit_kyc_use_case.dart';
import 'src/infrastructure/adapters/otp_repository_impl.dart';
import 'src/infrastructure/adapters/ocr_repository_impl.dart';
import 'src/infrastructure/adapters/kyc_repository_impl.dart';
import 'src/presentation/providers/kyc_provider.dart';
import 'src/presentation/screens/welcome_screen.dart';
import 'src/presentation/screens/privacy_consent_screen.dart';
import 'src/presentation/screens/phone_entry_screen.dart';
import 'src/presentation/screens/otp_screen.dart';
import 'src/presentation/screens/identity_screen.dart';
import 'src/presentation/screens/password_creation_screen.dart';
import 'src/presentation/screens/kyc_success_screen.dart';
import 'src/presentation/screens/account_analysis_screen.dart';
import 'src/presentation/screens/purpose_screen.dart';

class OnboardingModule extends IModule {
  late ApiClient _apiClient;
  // ignore: unused_field
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_onboarding';

  @override
  String get version => '1.0.0';

  @override
  void configure({required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<KycProvider>(
          create: (_) => KycProvider(
            sendOtp: SendOtpUseCase(OtpRepositoryImpl(apiClient: _apiClient)),
            verifyOtp: VerifyOtpUseCase(OtpRepositoryImpl(apiClient: _apiClient)),
            extractOcr: ExtractOcrUseCase(OcrRepositoryImpl(apiClient: _apiClient)),
            submitKyc: SubmitKycUseCase(KycRepositoryImpl(apiClient: _apiClient)),
          ),
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/onboarding',
          redirect: (_, __) => '/onboarding/welcome',
        ),
        GoRoute(
          path: '/onboarding/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/onboarding/privacy',
          builder: (_, __) => const PrivacyConsentScreen(),
        ),
        GoRoute(
          path: '/onboarding/purpose',
          builder: (_, __) => const PurposeScreen(),
        ),
        GoRoute(
          path: '/onboarding/phone',
          builder: (_, __) => const PhoneEntryScreen(),
        ),
        GoRoute(
          path: '/onboarding/otp',
          builder: (_, __) => const OtpScreen(),
        ),
        // Identidad: documentos + datos en una sola pantalla con pestañas.
        GoRoute(
          path: '/onboarding/identity',
          builder: (_, __) => const IdentityScreen(),
        ),
        // Las tres rutas anteriores (captura de INE, revisión de OCR y datos
        // personales) se fusionaron en `/onboarding/identity`. Se mantienen
        // como redirect para no romper deep links ni el back stack de sesiones
        // que quedaron a medias.
        GoRoute(
          path: '/onboarding/ine-capture',
          redirect: (_, __) => '/onboarding/identity',
        ),
        GoRoute(
          path: '/onboarding/ocr-review',
          redirect: (_, __) => '/onboarding/identity',
        ),
        GoRoute(
          path: '/onboarding/personal-data',
          redirect: (_, __) => '/onboarding/identity',
        ),
        GoRoute(
          path: '/onboarding/password',
          builder: (_, __) => const PasswordCreationScreen(),
        ),
        GoRoute(
          path: '/onboarding/analysis',
          // Sin transición: el análisis continúa en `/credit/after-analysis`
          // con la misma pantalla, y una animación de página entre las dos
          // mitades se ve como si el journey volviera a empezar.
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const AccountAnalysisScreen(),
          ),
        ),
        GoRoute(
          path: '/onboarding/success',
          builder: (_, __) => const KycSuccessScreen(),
        ),
      ];

  @override
  Widget? buildHomeCard(BuildContext context) => null;
}
