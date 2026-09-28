---
coyote: 1
repo: fintech-app
type: mobile
stack: [flutter, melos]
---
purpose|Fintech App es un monorepo Flutter gestionado con Melos que aplica el patrón de microfrontends a una app móvil: diez paquetes Dart/Flutter independientes —siete de dominio, dos de plataforma …
run|./run_local.sh
test|melos run test:all
dep|fintech-services|llama 35 endpoints de channel-mobile-service
mod|fa_credit|Fintech App Credit — crédito revolvente, pagos y disposición.|packages/fa_credit
mod|fa_placements|Fintech App Placements — colocación B2B2C: el distribuidor envía préstamos a sus beneficiarios con su línea.|packages/fa_placements
mod|fa_onboarding|Fintech App Onboarding — KYC, OTP, OCR de INE.|packages/fa_onboarding
mod|fa_notifications|Fintech App Notifications — bandeja de notificaciones y marcado como leído.|packages/fa_notifications
mod|fa_wallet|Fintech App Wallet — saldo, movimientos y transferencias (débito).|packages/fa_wallet
mod|fa_auth|Fintech App Auth — login, sesión y splash.|packages/fa_auth
mod|fa_profile|Fintech App Profile — perfil de usuario y datos personales.|packages/fa_profile
mod|fa_core|Fintech App — contratos compartidos, interfaces, ApiClient y AppConfig.|packages/fa_core
