import 'package:flutter_test/flutter_test.dart';

import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import 'test_data.dart';
import 'test_helpers.dart';

/// Pasos compartidos del alta, para que los cinco tests E2E que la recorren no
/// tengan cada uno su copia.
///
/// El alta cambió de forma con la integración del diseño Kredius: las tres
/// pantallas de identidad (`ine-capture` → `ocr-review` → `personal-data`) son
/// ahora **una sola** con segmented control, y con el orden invertido —
/// Documentos primero, Datos después, prellenados por el OCR del INE.
extension OnboardingSteps on WidgetTester {
  /// Los cuatro documentos del alta, con el nombre exacto que pinta la pestaña.
  static const documentos = [
    'INE · frente',
    'INE · reverso',
    'Selfie de vida',
    'Comprobante de domicilio',
  ];

  /// Marca los dos consentimientos **obligatorios** de la pantalla de
  /// privacidad. El tercero (marketing) es opcional y se deja sin marcar.
  ///
  /// No son `Checkbox` de Material: son cajas completas tocables, así que se
  /// tocan por su texto.
  Future<void> acceptLegalConsents() async {
    for (final anchor in [
      'Leí y acepto el aviso de privacidad',
      'Autorizo expresamente a Kredius',
    ]) {
      final finder = find.textContaining(anchor);
      if (finder.evaluate().isEmpty) continue;
      await ensureVisible(finder.first);
      await pumpAndSettle();
      await tap(finder.first, warnIfMissed: false);
      await pumpAndSettle();
    }
  }

  /// welcome → privacidad (paso 1).
  ///
  /// El alta abre con la autorización: nada se pide antes de tener permiso
  /// para pedirlo.
  Future<void> goToPrivacyStep() async {
    await tapButton('Empezar solicitud');
    await pumpAndSettle();
  }

  /// welcome → privacidad → propósito (paso 2).
  ///
  /// El propósito bifurca el alta: uso propio o colocación. Por defecto se toma
  /// "Para mí", que es el camino con ofertas aprobadas de inmediato.
  Future<void> goToPurposeStep() async {
    await goToPrivacyStep();
    await acceptLegalConsents();
    await tapButton('Autorizar y continuar');
    await pumpAndSettle();
  }

  /// welcome → … → celular (paso 3).
  Future<void> goToPhoneEntry({CreditPurpose? purpose}) async {
    await goToPurposeStep();
    await tapButton((purpose ?? CreditPurpose.usoPropio).title);
    await pumpAndSettle();
    await tapButton('Continuar');
    await pumpAndSettle();
  }

  /// welcome → … → OTP verificado → identidad (pestaña Documentos).
  Future<void> goToIdentityStep({String? phone, CreditPurpose? purpose}) async {
    await goToPhoneEntry(purpose: purpose);
    await enterField('Número celular', phone ?? TestData.phone);
    await enterField('Correo electrónico', TestData.email);
    await pumpAndSettle();
    // Continuar manda el código: la verificación va pegada a la captura.
    await tapButton('Continuar');
    await pumpAndSettle(const Duration(seconds: 2));
    await enterPinCode(TestData.otp);
    await pumpAndSettle(const Duration(seconds: 3));
  }

  /// Captura los cuatro documentos desde la galería mockeada.
  ///
  /// La selfie abre la cámara directo (una prueba de vida desde galería no
  /// tiene sentido); el mock de ImagePicker responde igual a ambas fuentes, así
  /// que la hoja de selección se toca sólo si apareció.
  Future<void> captureAllDocuments() async {
    await captureDocumentsOnly();
    await tapButton('Leer mis documentos');
    await pumpAndSettle();
  }

  /// Captura los documentos y **se queda en la pestaña Documentos**, para
  /// poder afirmar sobre la tarjeta de OCR antes de pasar a Datos.
  Future<void> captureDocumentsOnly() async {
    for (final doc in documentos) {
      final tile = find.text(doc);
      if (tile.evaluate().isEmpty) continue;
      await ensureVisible(tile.first);
      await pumpAndSettle();
      await tap(tile.first, warnIfMissed: false);
      await pumpAndSettle();

      final gallery = find.text('Elegir de la galería');
      if (gallery.evaluate().isNotEmpty) {
        await tap(gallery.first);
      }
      // El OCR se dispara solo al completar frente + reverso.
      await pumpAndSettle(const Duration(seconds: 3));
    }
  }

  /// Rellena la pestaña Datos.
  ///
  /// [curp] permite una identidad única por corrida: contra el backend real, origination
  /// rechaza por CURP duplicada, así que un valor fijo hace que el E2E sólo pase la primera
  /// vez. Contra el mock da igual, y por eso el default sigue siendo el de siempre.
  Future<void> fillIdentityData({String? curp}) async {
    await enterField('Nombres', TestData.nombres);
    await enterField('Apellido paterno', TestData.apellidoPaterno);
    await enterField('Apellido materno', TestData.apellidoMaterno);

    // Fecha de nacimiento y género vienen prellenados del OCR; no se abre el
    // date picker para no dejar el modal barrier bloqueando los dropdowns.
    await selectDropdown('Género', TestData.genero);
    await selectDropdown('Estado de nacimiento', TestData.estadoNacimiento);

    await enterField('CURP', curp ?? TestData.curp);
    await enterField('RFC', TestData.rfc);

    await scrollDown(amount: 400);
    await pumpAndSettle();

    await enterField('Calle', TestData.calle);
    await enterField('No. ext.', TestData.numExt);
    await enterField('Código postal', TestData.cp);
    await enterField('Colonia', TestData.colonia);

    await scrollDown(amount: 400);
    await pumpAndSettle();

    await enterField('Municipio / alcaldía', TestData.municipio);
    await enterField('Ciudad', TestData.ciudad);
    await selectDropdown('Estado', TestData.estadoDomicilio);

    await scrollDown(amount: 400);
    await pumpAndSettle();

    // Celular y correo ya no se capturan aquí: vienen del paso 3 y el celular
    // quedó verificado con el código, así que se muestran como dato.
    expect(find.byType(DsReadonlyField), findsNWidgets(2),
        reason: 'celular y correo se muestran, no se vuelven a pedir');
    expect(find.text('VERIFICADO'), findsOneWidget,
        reason: 'el celular verificado con el OTP lo dice');

    // Campo nuevo del diseño (Journey L1095).
    await enterField('Ingreso mensual', '18500');
  }

  /// Documentos + datos, de una.
  Future<void> completeIdentityStep({String? curp}) async {
    await captureAllDocuments();
    await fillIdentityData(curp: curp);
    await tapButton('Todo está correcto');
    await pumpAndSettle();
  }

  /// Crea la contraseña y espera a que el análisis del alta termine.
  ///
  /// "Crear cuenta" ya no lleva a una pantalla de éxito: lanza el análisis
  /// (crear cuenta + consultar buró y círculo + capacidad de pago) y de ahí
  /// salen las oportunidades. El anillo del análisis gira en bucle, así que
  /// **no se puede usar `pumpAndSettle`** mientras esté en pantalla.
  ///
  /// El destino depende del propósito: uso propio cae en las oportunidades y
  /// colocación cae en el home, porque su línea la decide un comité. Por eso
  /// [landing] es configurable — dar por hecho un solo desenlace ataba este
  /// helper al camino B2C.
  Future<void> completePasswordStep({Finder? landing, String? reason}) async {
    await enterField('Contraseña', TestData.password);
    await pumpAndSettle();
    await enterField('Confirmar contraseña', TestData.password);
    await pumpAndSettle();
    await tapButton('Crear cuenta');

    final llego = await pumpUntilFound(
      landing ?? find.text('Tus oportunidades'),
      maxTicks: 60,
      tick: const Duration(milliseconds: 500),
    );
    expect(llego, isTrue,
        reason: reason ??
            'el análisis del alta debe terminar en las oportunidades');
  }


}
