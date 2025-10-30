// lib/core/theme/app_theme.dart

// lib/core/theme/apptheme.dart (CORREÇÃO)

import 'package:flutter/material.dart';
// Mude para o import via package:
import 'package:appetite/core/constants/appcolors.dart'; 

// ... (Resto do código do buildAppTheme)

// MODIFICAÇÃO: A função agora recebe o fator de escala de fonte
ThemeData buildAppTheme(Color primaryColor, double fontSizeFactor) {
  // Define o TextTheme padrão, escalando cada tamanho pelo fator
  final baseTextTheme = const TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontSize: 57),
    displayMedium: TextStyle(color: Colors.white, fontSize: 45),
    displaySmall: TextStyle(color: Colors.white, fontSize: 36),
    headlineLarge: TextStyle(color: Colors.white, fontSize: 32),
    headlineMedium: TextStyle(color: Colors.white, fontSize: 28),
    headlineSmall: TextStyle(color: Colors.white, fontSize: 24),
    titleLarge: TextStyle(color: Colors.white, fontSize: 22),
    titleMedium: TextStyle(color: Colors.white, fontSize: 16),
    titleSmall: TextStyle(color: Colors.white, fontSize: 14),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    bodySmall: TextStyle(color: Colors.white60, fontSize: 12),
    labelLarge: TextStyle(color: Colors.black, fontSize: 14),
    labelMedium: TextStyle(color: Colors.white70, fontSize: 12),
    labelSmall: TextStyle(color: Colors.white60, fontSize: 11),
  );

  return ThemeData(
    primaryColor: primaryColor, 
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: AppColors.accentColor,
      primary: primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      // O título do App Bar também deve escalar
      titleTextStyle: baseTextTheme.titleLarge?.copyWith(
        fontSize: (baseTextTheme.titleLarge?.fontSize ?? 22) * fontSizeFactor,
        fontWeight: FontWeight.bold,
      ),
      elevation: 0,
    ),
    
    // APLICAÇÃO GLOBAL: Usa o fator de escala no TextTheme.
    textTheme: baseTextTheme.apply(
        fontSizeFactor: fontSizeFactor,
    ),

    brightness: Brightness.dark,
  );
}