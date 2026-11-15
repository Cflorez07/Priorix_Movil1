import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/priorix_theme.dart';
import '../../core/widgets/priorix_logo.dart';
import '../auth/login_page.dart';
import '../dashboard/role_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _inicializarApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _inicializarApp() async {
    // Garantizamos mínimo 1.8 segundos para visualización institucional y máximo 3s de timeout
    final stopwatch = Stopwatch()..start();

    bool sesionValida = false;
    final session = SessionService.instance;

    try {
      if (session.isAuthenticated) {
        // Verificamos conectividad o validez del token con timeout defensivo
        try {
          await ApiClient.instance.getMe().timeout(const Duration(milliseconds: 1500));
          sesionValida = true;
        } catch (_) {
          // Si no hay red pero el token existe localmente, se mantiene sesión offline
          sesionValida = session.token != null && session.token!.isNotEmpty;
        }
      }
    } catch (_) {
      sesionValida = false;
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 1800) {
      await Future.delayed(Duration(milliseconds: 1800 - elapsed));
    }

    if (!mounted) return;

    if (sesionValida) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => RoleDashboard(role: session.rolLegible),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriorixColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Logotipo con animación de pulso sutil
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: const PriorixLogo(
                  size: 96,
                  showText: true,
                  showSlogan: true,
                ),
              ),

              const SizedBox(height: 48),

              // Barra de progreso elegante
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: PriorixColors.cardSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(PriorixColors.primaryBlue),
                  ),
                ),
              ),

              const Spacer(),

              // Versión en la parte inferior
              const Text(
                'Versión 1.0',
                style: TextStyle(
                  color: PriorixColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
