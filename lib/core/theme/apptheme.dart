// lib/core/theme/apptheme.dart
import 'package:flutter/material.dart';
import 'package:appetite/core/constants/app_colors.dart'; // MANTEMOS ESTE IMPORT!

// MODIFICAÇÃO: A função agora recebe um Brightness
ThemeData buildAppTheme(Color primaryColor, double fontSizeFactor, Brightness brightness) {
  // Define a cor de fundo e de texto baseadas no brilho
  final bool isDark = brightness == Brightness.dark;
  final Color backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
  final Color textColor = isDark ? Colors.white : Colors.black;
  final Color secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

  final baseTextTheme = TextTheme(
    displayLarge: TextStyle(color: textColor, fontSize: 57),
    displayMedium: TextStyle(color: textColor, fontSize: 45),
    displaySmall: TextStyle(color: textColor, fontSize: 36),
    headlineLarge: TextStyle(color: textColor, fontSize: 32),
    headlineMedium: TextStyle(color: textColor, fontSize: 28),
    headlineSmall: TextStyle(color: textColor, fontSize: 24),
    titleLarge: TextStyle(color: textColor, fontSize: 22),
    titleMedium: TextStyle(color: secondaryTextColor, fontSize: 16),
    titleSmall: TextStyle(color: secondaryTextColor, fontSize: 14),
    bodyLarge: TextStyle(color: textColor, fontSize: 16),
    bodyMedium: TextStyle(color: secondaryTextColor, fontSize: 14),
    bodySmall: TextStyle(color: secondaryTextColor, fontSize: 12),
    labelLarge: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 14), // Botões
    labelMedium: TextStyle(color: secondaryTextColor, fontSize: 12),
    labelSmall: TextStyle(color: secondaryTextColor, fontSize: 11),
  );

  return ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: MaterialColor(primaryColor.value, AppColors.getMaterialColorMap(primaryColor)),
      accentColor: AppColors.accentColor, // Use accentColor se necessário
      brightness: brightness, // Usa o brilho passado
      backgroundColor: backgroundColor,
    ).copyWith(
      primary: primaryColor,
      secondary: AppColors.accentColor,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: backgroundColor, // Fundo principal da tela
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      titleTextStyle: baseTextTheme.titleLarge?.copyWith(
        fontSize: (baseTextTheme.titleLarge?.fontSize ?? 22) * fontSizeFactor,
        fontWeight: FontWeight.bold,
        color: textColor, // Cor do título do App Bar
      ),
      iconTheme: IconThemeData(color: textColor), // Cor dos ícones no App Bar
      elevation: 0,
    ),
    textTheme: baseTextTheme.apply(
        fontSizeFactor: fontSizeFactor,
        bodyColor: textColor,
        displayColor: textColor,
    ),
    brightness: brightness, // Define o brilho geral do tema
  );
}

// REMOVIDA DAQUI - ESTÁ NO SEU PRÓPRIO ARQUIVO: lib/core/constants/app_colors.dart
// class AppColors { ... }