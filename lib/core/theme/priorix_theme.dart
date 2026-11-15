import 'package:flutter/material.dart';

abstract final class PriorixColors {
  // Paleta Institucional PRIORIX Web
  static const background = Color(0xFF0F1B2D); // #0F1B2D
  static const card = Color(0xFF14233A);       // #14233A
  static const cardSecondary = Color(0xFF1A2D48); // #1A2D48
  static const border = Color(0xFF243955);     // #243955
  static const textPrimary = Color(0xFFE8EEF8); // #E8EEF8
  static const textSecondary = Color(0xFF93A6C3); // #93A6C3
  static const primaryBlue = Color(0xFF4A9BE8); // #4A9BE8
  static const deepBlue = Color(0xFF2A73D6);    // #2A73D6

  // Alias compatibles con código existente
  static const navy = background;
  static const navyLight = cardSecondary;
  static const surface = card;
  static const surfaceAlt = cardSecondary;
  static const blue = deepBlue;
  static const blueLight = primaryBlue;
  static const white = textPrimary;
  static const muted = textSecondary;

  // Colores Oficiales de Niveles de Triaje (PRIORIX Web / NivelTriaje)
  static const nivel1Rojo = Color(0xFFC62828);     // Nivel 1 - Rojo
  static const nivel2Naranja = Color(0xFFE65100);  // Nivel 2 - Naranja
  static const nivel3Amarillo = Color(0xFFF9A825); // Nivel 3 - Amarillo
  static const nivel4Azul = Color(0xFF1565C0);     // Nivel 4 - Azul
  static const nivel5Verde = Color(0xFF2E7D32);    // Nivel 5 - Verde

  // Compatibilidad
  static const red = nivel1Rojo;
  static const orange = nivel2Naranja;
  static const yellow = nivel3Amarillo;
  static const triageBlue = nivel4Azul;
  static const green = nivel5Verde;

  // Estados de conexión
  static const onlineGreen = Color(0xFF2E7D32);
  static const onlineGreenLight = Color(0xFF6FD39B);
  static const offlineOrange = Color(0xFFE65100);
  static const offlineOrangeLight = Color(0xFFFFA726);

  static Color colorPorNivel(int? nivel) {
    switch (nivel) {
      case 1:
        return nivel1Rojo;
      case 2:
        return nivel2Naranja;
      case 3:
        return nivel3Amarillo;
      case 4:
        return nivel4Azul;
      case 5:
        return nivel5Verde;
      default:
        return primaryBlue;
    }
  }

  static String nombreNivel(int? nivel) {
    switch (nivel) {
      case 1:
        return 'Nivel I · Reanimación (Rojo)';
      case 2:
        return 'Nivel II · Emergencia (Naranja)';
      case 3:
        return 'Nivel III · Urgencia (Amarillo)';
      case 4:
        return 'Nivel IV · Prioritario (Azul)';
      case 5:
        return 'Nivel V · No urgente (Verde)';
      default:
        return 'Sin clasificar';
    }
  }
}

class PriorixTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PriorixColors.primaryBlue,
      brightness: Brightness.dark,
      surface: PriorixColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Montserrat',
      colorScheme: scheme.copyWith(
        primary: PriorixColors.primaryBlue,
        secondary: PriorixColors.deepBlue,
        surface: PriorixColors.card,
        error: PriorixColors.nivel1Rojo,
      ),
      scaffoldBackgroundColor: PriorixColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: PriorixColors.background,
        foregroundColor: PriorixColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: PriorixColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PriorixColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PriorixColors.cardSecondary,
        hintStyle: const TextStyle(color: PriorixColors.textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: PriorixColors.textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PriorixColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PriorixColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PriorixColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PriorixColors.nivel1Rojo),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PriorixColors.primaryBlue,
          foregroundColor: const Color(0xFF0F1B2D),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: PriorixColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: PriorixColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: PriorixColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: PriorixColors.textPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: PriorixColors.textSecondary,
          fontSize: 12,
        ),
      ),
      dividerColor: PriorixColors.border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PriorixColors.cardSecondary,
        contentTextStyle: const TextStyle(color: PriorixColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: PriorixColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
