/// La prelación de las cards del home.
///
/// El orden no es estético: primero la línea de distribuidor —el dinero del que
/// el titular responde—, luego sus créditos propios y al final lo que se le
/// ofrece. Este test lo fija para que no vuelva a depender de en qué renglón
/// quedó cada módulo en `ShellInjection`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_credit/credit_module.dart';
import 'package:fa_placements/placements_module.dart';
import 'package:fa_notifications/notifications_module.dart';
import 'package:fa_wallet/wallet_module.dart';

void main() {
  test('la línea de distribuidor va antes que los créditos propios', () {
    expect(PlacementsModule().homeCardOrder,
        lessThan(CreditModule().homeCardOrder),
        reason: 'la línea arrastra la deuda de todas sus colocaciones');
  });

  test('los módulos sin prelación declarada caen al final', () {
    for (final modulo in <IModule>[WalletModule(), NotificationsModule()]) {
      expect(modulo.homeCardOrder,
          greaterThan(CreditModule().homeCardOrder),
          reason: '${modulo.moduleId} no debe colarse entre línea y créditos');
    }
  });

  test('ordenar por prelación deja línea → créditos → resto', () {
    // Registrados al revés a propósito: el orden de registro no debe mandar.
    final modules = <IModule>[
      NotificationsModule(),
      CreditModule(),
      WalletModule(),
      PlacementsModule(),
    ];
    final ordenadas = [...modules]
      ..sort((a, b) => a.homeCardOrder.compareTo(b.homeCardOrder));

    expect(ordenadas.first.moduleId, PlacementsModule().moduleId);
    expect(ordenadas[1].moduleId, CreditModule().moduleId);
  });
}
