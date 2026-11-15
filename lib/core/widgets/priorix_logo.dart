import 'package:flutter/material.dart';
import '../theme/priorix_theme.dart';

class PriorixLogo extends StatelessWidget {
  const PriorixLogo({
    super.key,
    this.size = 64,
    this.showText = true,
    this.showSlogan = true,
    this.compact = false,
  });

  final double size;
  final bool showText;
  final bool showSlogan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // El logo institucional ya incluye el isotipo (cruz con pulso) y la palabra PRIORIX.
      return _buildLogoImage(height: 28);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLogoImage(height: size),
        if (showSlogan) ...[
          const SizedBox(height: 10),
          const Text(
            'Priorizamos tu salud, agilizamos tu atención.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: PriorixColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoImage({required double height}) {
    return Image.asset(
      'assets/images/priorix-logo-transparente-claro.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback visual si el asset no está disponible
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_rounded,
              size: height * 0.9,
              color: PriorixColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: height * 0.65,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: PriorixColors.textPrimary,
                ),
                children: const [
                  TextSpan(text: 'PRIORI'),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(
                      color: PriorixColors.primaryBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
