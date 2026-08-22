import 'package:fa_core/fa_core.dart';
import 'package:fa_auth/fa_auth.dart';
import 'package:fa_onboarding/fa_onboarding.dart';
import 'package:fa_wallet/fa_wallet.dart';
import 'package:fa_credit/fa_credit.dart';
import 'package:fa_placements/fa_placements.dart';
import 'package:fa_notifications/fa_notifications.dart';
import 'package:fa_profile/fa_profile.dart';
import '../network/dio_api_client.dart';

abstract final class ShellInjection {
  static ApiClient buildApiClient() {
    if (AppConfig.current.isMock) {
      return DioApiClient(
        baseUrl: AppConfig.current.bffUrl,
        interceptors: [
          AuthMockInterceptor(),
          OnboardingMockInterceptor(),
          WalletMockInterceptor(),
          // El mock de crédito avisa de lo que ocurre y el de notificaciones
          // lo convierte en un aviso para el usuario. Los dos módulos no se
          // conocen entre sí: el cableado vive aquí, que es quien conoce a
          // ambos. Sólo aplica al flavor mock.
          CreditMockInterceptor(onEvent: _onCreditMockEvent),
          PlacementsMockInterceptor(onEvent: _onPlacementMockEvent),
          NotificationsMockInterceptor(),
          ProfileMockInterceptor(),
        ],
      );
    }
    return DioApiClient(baseUrl: AppConfig.current.bffUrl);
  }

  /// Traduce un hecho del crédito en la notificación que le llegaría al
  /// usuario, con el mismo texto que el prototipo (Journey L1438–L1444).
  static void _onCreditMockEvent(CreditMockEvent e) {
    final monto = e.amount.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    switch (e.kind) {
      case CreditMockEventKind.disbursed:
        NotificationsMockInterceptor.push(
          id: 'live-disbursed',
          type: 'paymentReceived',
          title: 'Tu dinero va en camino',
          body: 'Depositamos \$$monto a tu cuenta. Ya puedes verlo en tu inicio.',
          actionRoute: '/home',
        );
        NotificationsMockInterceptor.push(
          id: 'live-contract',
          type: 'statement',
          title: 'Tu contrato ya está firmado',
          body: 'Guardamos el PDF en tu perfil. Puedes descargarlo cuando quieras.',
        );
      case CreditMockEventKind.paymentApplied:
        NotificationsMockInterceptor.push(
          id: 'live-payment-${e.paymentsMade}',
          type: 'paymentReceived',
          title: 'Recibimos tu pago de \$$monto',
          body: 'Aplicado a tu crédito: pago ${e.paymentsMade} de ${e.term}. '
              'Tu saldo ya está actualizado.',
          actionRoute: '/home',
        );
      case CreditMockEventKind.installmentDue:
        NotificationsMockInterceptor.push(
          id: 'live-due-${e.paymentsMade + 1}',
          type: 'paymentDue',
          title: 'Tu pago está por vencer',
          body: 'La mensualidad ${e.paymentsMade + 1} de ${e.term} es de '
              '\$$monto. Págala a tiempo para no generar moratorios.',
          actionRoute: '/home',
        );
      case CreditMockEventKind.installmentOverdue:
        // Se avisa con el número de pago y los días: "tienes un adeudo" a secas
        // no dice qué pagar ni desde cuándo.
        NotificationsMockInterceptor.push(
          id: 'live-overdue-${e.paymentsMade + 1}',
          type: 'paymentDue',
          title: 'Tu crédito está en mora',
          body: 'La mensualidad ${e.paymentsMade + 1} de ${e.term} venció hace '
              '${e.daysPastDue} ${e.daysPastDue == 1 ? 'día' : 'días'}. '
              'Ponte al corriente para dejar de generar moratorios.',
          actionRoute: '/home',
        );
      case CreditMockEventKind.creditPaidOff:
        // Liquidar es la mejor noticia del crédito y merece su propio aviso:
        // enterarse de que ya no debes nada por un "van 12 de 12" es enterarse
        // a medias.
        NotificationsMockInterceptor.push(
          id: 'live-paid-off',
          type: 'paymentReceived',
          title: '¡Liquidaste tu crédito!',
          body: 'Con este pago de \$$monto cerraste tus ${e.term} '
              'mensualidades. Tu historial lo agradece.',
          actionRoute: '/home',
        );
        NotificationsMockInterceptor.push(
          id: 'live-paid-off-offer',
          type: 'offer',
          title: 'Tu buen historial abre otra línea',
          body: 'Por pagar puntual, tienes una nueva oferta preaprobada '
              'esperándote.',
          actionRoute: '/credit/apply',
        );
    }
  }

  /// Lo mismo para la colocación: el distribuidor no está mirando la app
  /// mientras su clienta se verifica en otro teléfono, así que el aviso es la
  /// única forma de enterarse de que ya le toca decidir.
  static void _onPlacementMockEvent(PlacementMockEvent e) {
    final monto = e.amount.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    switch (e.kind) {
      case PlacementMockEventKind.inviteSent:
        NotificationsMockInterceptor.push(
          id: 'live-placement-sent-${e.placementId}',
          type: 'statement',
          title: 'Le mandamos la liga a ${e.beneficiaryName}',
          body: 'Vive 7 días. Te avisamos en cuanto termine su verificación.',
        );
      case PlacementMockEventKind.bureauReady:
        NotificationsMockInterceptor.push(
          id: 'live-placement-bureau-${e.placementId}',
          type: 'offer',
          title: '${e.beneficiaryName} ya se verificó',
          body: 'Su historial está listo. Revísalo para decidir si le colocas.',
          actionRoute: '/placements/${e.placementId}/bureau',
        );
      case PlacementMockEventKind.disbursed:
        NotificationsMockInterceptor.push(
          id: 'live-placement-disbursed-${e.placementId}',
          type: 'paymentReceived',
          title: 'Colocación enviada a ${e.beneficiaryName}',
          body: 'Depositamos \$$monto a su cuenta. Ya se descontó de tu línea.',
          actionRoute: '/home',
        );
      case PlacementMockEventKind.inviteExpired:
        NotificationsMockInterceptor.push(
          id: 'live-placement-expired-${e.placementId}',
          type: 'paymentDue',
          title: 'La liga de ${e.beneficiaryName} venció',
          body: 'No completó su verificación en 7 días. Tu línea sigue intacta; '
              'puedes volver a enviársela.',
        );
    }
  }

  static List<IModule> buildModules({
    required ApiClient apiClient,
    required NavigationCallbacks navigation,
  }) {
    final modules = <IModule>[
      AuthModule(),
      OnboardingModule(),
      WalletModule(),
      CreditModule(),
      PlacementsModule(),
      NotificationsModule(),
      ProfileModule(),
    ];
    for (final m in modules) {
      m.configure(apiClient: apiClient, navigation: navigation);
    }
    return modules;
  }
}
