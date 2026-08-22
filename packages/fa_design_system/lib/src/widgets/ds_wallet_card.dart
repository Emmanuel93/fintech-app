import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../theme/app_text_styles.dart';

/// Tarjeta de débito Kredius: saldo, CLABE/número enmascarado, toggle de
/// visibilidad. Usada en el home (`fa_wallet`) y reutilizable donde más se
/// necesite mostrar el wallet de forma consistente.
class DsWalletCard extends StatelessWidget {
  const DsWalletCard({
    super.key,
    required this.balance,
    required this.accountNumber,
    required this.clabe,
    required this.visible,
    required this.onToggleVisibility,
  });

  final double balance;
  final String accountNumber;
  final String? clabe;
  final bool visible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final hasClabe = clabe != null && clabe!.isNotEmpty;
    final last4 = hasClabe
        ? clabe!.substring(clabe!.length - 4)
        : (accountNumber.length >= 4
            ? accountNumber.substring(accountNumber.length - 4)
            : accountNumber);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: h * 0.26,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1A237E), Color(0xFF0A1972)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -w * 0.12,
              top: -h * 0.04,
              child: Container(
                width: w * 0.55,
                height: w * 0.55,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            Positioned(
              left: -w * 0.08,
              bottom: -h * 0.06,
              child: Container(
                width: w * 0.45,
                height: w * 0.45,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(w * 0.058),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('KREDIUS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: h * 0.016,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2)),
                      GestureDetector(
                        onTap: onToggleVisibility,
                        child: Icon(
                          visible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white54,
                          size: h * 0.024,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: h * 0.038,
                        height: h * 0.028,
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(4)),
                        child: CustomPaint(painter: _ChipPainter()),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Saldo disponible',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: h * 0.013)),
                          Text(
                            visible ? fmt.format(balance) : '•••••••',
                            style: AppTextStyles.heroNumber(h * 0.034, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Gap(h * 0.016),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(hasClabe ? 'CLABE •••• $last4' : '•••• •••• •••• $last4',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: h * 0.016,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500)),
                      Text(hasClabe ? 'DEPÓSITO' : 'DÉBITO',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: h * 0.013,
                              letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.5,
          height: size.height * 0.5),
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
