import 'package:flutter/material.dart';
import 'core/theme/priorix_theme.dart';
import 'core/widgets/global_app_overlay.dart';
import 'features/splash/splash_screen.dart';

class PriorixApp extends StatelessWidget {
  const PriorixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRIORIX',
      debugShowCheckedModeBanner: false,
      theme: PriorixTheme.dark(),
      home: const SplashScreen(),
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (ctx) => GlobalAppOverlay(child: child),
            ),
          ],
        );
      },
    );
  }
}
