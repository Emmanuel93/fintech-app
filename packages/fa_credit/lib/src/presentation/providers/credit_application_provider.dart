import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fa_core/fa_core.dart';

import '../../application/use_cases/list_products_use_case.dart';
import '../../application/use_cases/list_prequalified_products_use_case.dart';
import '../../application/use_cases/submit_application_use_case.dart';
import '../../application/use_cases/get_application_use_case.dart';
import '../../application/use_cases/present_offer_use_case.dart';
import '../../application/use_cases/accept_offer_use_case.dart';
import '../../application/use_cases/generate_contract_use_case.dart';
import '../../application/use_cases/sign_contract_use_case.dart';
import '../../domain/entities/credit_product.dart';
import '../../domain/entities/credit_application.dart';
import '../../domain/entities/prequalified_product.dart';

/// Orquesta el flujo de solicitud de crédito (ADR-001): catálogo → selección de
/// producto → aplicación → scoring → oferta → aceptación → contrato → firma.
class CreditApplicationProvider extends ChangeNotifier with SafeNotifier {
  CreditApplicationProvider({
    required ListProductsUseCase listProducts,
    required ListPrequalifiedProductsUseCase listPrequalifiedProducts,
    required SubmitApplicationUseCase submitApplication,
    required GetApplicationUseCase getApplication,
    required PresentOfferUseCase presentOffer,
    required AcceptOfferUseCase acceptOffer,
    required GenerateContractUseCase generateContract,
    required SignContractUseCase signContract,
  })  : _listProducts = listProducts,
        _listPrequalifiedProducts = listPrequalifiedProducts,
        _submitApplication = submitApplication,
        _getApplication = getApplication,
        _presentOffer = presentOffer,
        _acceptOffer = acceptOffer,
        _generateContract = generateContract,
        _signContract = signContract;

  final ListProductsUseCase _listProducts;
  final ListPrequalifiedProductsUseCase _listPrequalifiedProducts;
  final SubmitApplicationUseCase _submitApplication;
  final GetApplicationUseCase _getApplication;
  final PresentOfferUseCase _presentOffer;
  final AcceptOfferUseCase _acceptOffer;
  final GenerateContractUseCase _generateContract;
  final SignContractUseCase _signContract;

  List<CreditProduct> products = const [];
  List<PrequalifiedProduct> prequalifiedProducts = const [];
  bool isLoadingPrequalified = false;
  CreditProduct? selectedProduct;
  CreditApplication? application;

  bool isLoading = false;
  bool isSubmitting = false;
  bool isActing = false; // acciones de oferta/contrato en curso
  String? error;

  // ── Catálogo ───────────────────────────────────────────────────────────
  Future<void> loadProducts() async {
    isLoading = true;
    error = null;
    notificar();
    try {
      products = await _listProducts();
    } catch (e, st) {
      // ignore: avoid_print
      print('[loadProducts] EXCEPTION: $e\n$st');
      error = 'No pudimos cargar los productos de crédito.';
    } finally {
      isLoading = false;
      notificar();
    }
  }

  void selectProduct(CreditProduct product) {
    selectedProduct = product;
    selectedPrequalified = null;
    notificar();
  }

  /// Créditos B2C preaprobados para el home. Falla en silencio a propósito: un
  /// hiccup de scoring-service nunca debe bloquear ni mostrar error en el home,
  /// solo hace que la UI caiga al CTA genérico existente (ver credit_module.dart).
  Future<void> loadPrequalifiedProducts() async {
    isLoadingPrequalified = true;
    notificar();
    try {
      prequalifiedProducts = await _listPrequalifiedProducts();
    } catch (e, st) {
      // ignore: avoid_print
      print('[loadPrequalifiedProducts] EXCEPTION: $e\n$st');
      prequalifiedProducts = const [];
    } finally {
      isLoadingPrequalified = false;
      notificar();
    }
  }

  /// Elegir desde oportunidades conserva la preoferta, no sólo el producto.
  ///
  /// Es la diferencia entre configurar sobre el rango del catálogo y
  /// configurar sobre lo que el scoring autorizó: `item.offer` ya trae los
  /// topes recortados, así que el slider no puede llegar a un monto que
  /// después se rechace.
  void selectPrequalifiedProduct(PrequalifiedProduct item) {
    selectedProduct = item.offer;
    selectedPrequalified = item;
    notificar();
  }

  /// La preoferta detrás del producto elegido, cuando se eligió desde
  /// oportunidades. `null` si se llegó por el catálogo genérico.
  PrequalifiedProduct? selectedPrequalified;

  // ── Segmentación por propósito ───────────────────────────────────────────
  //
  // Quien pide para sí no debe ver líneas de distribuidor, y al revés. El
  // filtro se aplica sobre `targetAudience` del catálogo.

  /// Precalificados que corresponden al propósito elegido en el alta.
  List<PrequalifiedProduct> get purposeProducts {
    final purpose = AppSession.instance.purpose;
    return prequalifiedProducts
        .where((p) => purpose.matches(p.product.targetAudience))
        .toList();
  }

  /// Los que ya pasaron scoring y se pueden tomar hoy.
  List<PrequalifiedProduct> get approvedProducts =>
      purposeProducts.where((p) => p.isAutoApproved).toList();

  /// Los que existen para este propósito pero necesitan comité o más datos.
  List<PrequalifiedProduct> get onReviewProducts =>
      purposeProducts.where((p) => !p.isAutoApproved).toList();

  /// A dónde lleva el análisis del alta.
  ///
  /// Si hay algo aprobado, a las oportunidades: hay una oferta real que tomar.
  /// Si no —el caso típico del distribuidor, cuyo producto pasa a comité— al
  /// home, que muestra el estado "en revisión" en vez de un catálogo que no
  /// puede contratar todavía.
  String get postAnalysisRoute =>
      approvedProducts.isNotEmpty ? '/credit/apply' : '/home';

  /// `true` cuando el prospecto tiene solicitudes esperando comité y ninguna
  /// oferta lista — el home lo comunica en lugar del estado vacío genérico.
  bool get isPendingReview =>
      approvedProducts.isEmpty && onReviewProducts.isNotEmpty;

  // ── Monto y plazo elegidos, a la espera del consentimiento de buró ───────
  //
  // La solicitud no se crea al salir del configurador: se crea al autorizar la
  // consulta a las SIC, que es el paso siguiente. Entre una pantalla y otra el
  // monto vive aquí.
  double? _stagedAmount;
  int? _stagedTerm;

  void stageAmount({double? amount, int? term}) {
    _stagedAmount = amount;
    _stagedTerm = term;
  }

  /// Crea la solicitud con lo que quedó en [stageAmount].
  Future<bool> submitPending() =>
      submit(amount: _stagedAmount, term: _stagedTerm);

  /// La oferta autorizada es **menor** a lo que se pidió: el journey desvía a
  /// la pantalla de contraoferta (Journey L807–L836) en vez de presentar la
  /// oferta como si fuera lo solicitado.
  bool get isCounterOffer {
    final requested = _stagedAmount;
    final offered = application?.offerAmountOrLine;
    if (requested == null || offered == null) return false;
    // Un peso de diferencia por redondeo no es una contraoferta.
    return offered < requested - 1;
  }

  // ── Crear aplicación ─────────────────────────────────────────────────────
  Future<bool> submit({double? amount, int? term}) async {
    final product = selectedProduct;
    if (product == null) return false;
    isSubmitting = true;
    error = null;
    notificar();
    try {
      // ignore: avoid_print
      print('[submit] prospectId=${AppSession.instance.prospectId} '
          'productType=${product.productType} amount=$amount term=$term');
      application = await _submitApplication(
        prospectId: AppSession.instance.prospectId,
        productType: product.productType,
        requestedAmount: amount,
        requestedTerm: term,
      );
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('[submit] EXCEPTION: $e\n$st');
      error = 'No pudimos enviar tu solicitud. Intenta de nuevo.';
      return false;
    } finally {
      isSubmitting = false;
      notificar();
    }
  }

  // ── Polling de la decisión de scoring ────────────────────────────────────
  Timer? _pollTimer;

  void startPolling() {
    final app = application;
    if (app == null || !app.isPending) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    final current = application;
    if (current == null) {
      _stopPolling();
      return;
    }
    try {
      final updated = await _getApplication(current.applicationId);
      application = updated;
      notificar();
      if (updated.isApproved) {
        // Aprobado por scoring/comité → presentamos la oferta automáticamente.
        _stopPolling();
        await presentOffer();
      } else if (!updated.isPending) {
        // manualReview / rejected / ya con oferta → dejamos de sondear.
        _stopPolling();
      }
    } catch (_) {
      // Reintenta en el siguiente tick.
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Oferta / contrato ────────────────────────────────────────────────────
  Future<void> presentOffer() async {
    final app = application;
    if (app == null) return;
    isActing = true;
    notificar();
    try {
      application = await _presentOffer(app.applicationId);
    } catch (_) {
      error = 'No pudimos presentar tu oferta. Intenta de nuevo.';
    } finally {
      isActing = false;
      notificar();
    }
  }

  /// Acepta la oferta y genera el contrato (queda en PENDING_SIGNATURE).
  Future<bool> acceptOffer() async {
    final app = application;
    if (app == null) return false;
    isActing = true;
    error = null;
    notificar();
    try {
      await _acceptOffer(app.applicationId);
      application = await _generateContract(app.applicationId);
      return true;
    } catch (_) {
      error = 'No pudimos continuar con la oferta. Intenta de nuevo.';
      return false;
    } finally {
      isActing = false;
      notificar();
    }
  }

  Future<bool> signContract({required String clabe, required String signatureProof}) async {
    final app = application;
    if (app == null) return false;
    isActing = true;
    error = null;
    notificar();
    try {
      application = await _signContract(
        applicationId: app.applicationId,
        clabeAccount: clabe,
        signatureProof: signatureProof,
      );
      return application?.isContractSigned ?? false;
    } catch (_) {
      error = 'No pudimos firmar tu contrato. Verifica la CLABE e intenta de nuevo.';
      return false;
    } finally {
      isActing = false;
      notificar();
    }
  }

  // ── CLABE de desembolso, entre el resumen y la firma ─────────────────────
  //
  // El resumen la captura o la toma de la wallet; la pantalla de OTP la
  // necesita para firmar. Vive aquí en medio para no pasarla por la ruta.
  String? _stagedClabe;
  String? get stagedClabe => _stagedClabe;

  void stageClabe(String clabe) => _stagedClabe = clabe;

  /// Firma con la CLABE que dejó el resumen y el código capturado en el
  /// teclado de la pantalla de OTP.
  Future<bool> signStagedContract({required String signatureProof}) async {
    final clabe = _stagedClabe;
    if (clabe == null) {
      error = 'Falta la cuenta de depósito.';
      notificar();
      return false;
    }
    return signContract(clabe: clabe, signatureProof: signatureProof);
  }

  // ── Contrato firmado ─────────────────────────────────────────────────────
  Uint8List? _signedPdf;
  Uint8List? _signatureImage;

  /// PDF del contrato con la firma ya estampada.
  Uint8List? get signedPdf => _signedPdf;
  Uint8List? get signatureImage => _signatureImage;

  void stageSignedContract({Uint8List? pdf, Uint8List? signature}) {
    _signedPdf = pdf;
    _signatureImage = signature;
  }

  /// Las condiciones con las que se arma el calendario de pagos.
  ///
  /// Un único punto para que el resumen, el contrato y la tabla hablen del
  /// mismo crédito: la solicitud manda si ya existe (es lo resuelto), y si no,
  /// lo que se está configurando. La tasa cae al producto porque el BFF la
  /// manda ahí y no siempre en la solicitud.
  ({
    double amount,
    int termInMonths,
    double annualRate,
    String paymentFrequency,
    DateTime? from,
  })? get scheduleTerms {
    final product = selectedProduct;
    final app = application;
    final amount = app?.offerAmountOrLine ?? _stagedAmount;
    final term = app?.offeredTerm ?? _stagedTerm;
    final rate = app?.nominalRate ?? product?.nominalRate;
    if (amount == null || amount <= 0 || term == null || rate == null) {
      return null;
    }
    return (
      amount: amount,
      termInMonths: term,
      annualRate: rate,
      paymentFrequency: product?.defaultPaymentFrequency ?? 'MONTHLY',
      from: null,
    );
  }

  /// Titular y CURP para el clausulado. Salen del alta, que ya los capturó.
  String get holderName =>
      AppSession.instance.holderName.isNotEmpty
          ? AppSession.instance.holderName
          : 'Titular Kredius';

  String get holderCurp => AppSession.instance.holderCurp;

  /// Celular enmascarado para la pantalla de firma — "55 •• •• 42 18" en el
  /// prototipo (Journey L530). Sale de la sesión, no de la aplicación.
  String get maskedPhone {
    final phone = AppSession.instance.phone;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'tu celular';
    return '${digits.substring(0, 2)} •• •• '
        '${digits.substring(6, 8)} ${digits.substring(8)}';
  }

  void reset() {
    _stopPolling();
    selectedProduct = null;
    application = null;
    error = null;
    isSubmitting = false;
    isActing = false;
    _stagedAmount = null;
    _stagedTerm = null;
    _stagedClabe = null;
    _signedPdf = null;
    _signatureImage = null;
    notificar();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
