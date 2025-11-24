import 'package:flutter/material.dart';
import 'package:appetite/core/constants/appcolors.dart';

ThemeData buildAppTheme(Color primaryColor, double fontSizeFactor, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Define as cores base dependendo do modo
  final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final textColor = isDark ? Colors.white : Colors.black87;
  final subTextColor = isDark ? Colors.white70 : Colors.black54;

  // Base de texto que se adapta a cor
  final baseTextTheme = TextTheme(
    displayLarge: TextStyle(color: textColor, fontSize: 57),
    headlineSmall: TextStyle(color: textColor, fontSize: 24),
    titleLarge: TextStyle(color: textColor, fontSize: 22),
    titleMedium: TextStyle(color: textColor, fontSize: 16),
    bodyLarge: TextStyle(color: textColor, fontSize: 16),
    bodyMedium: TextStyle(color: subTextColor, fontSize: 14),
    bodySmall: TextStyle(color: subTextColor, fontSize: 12),
  );

  return ThemeData(
    primaryColor: primaryColor,
    brightness: brightness,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor, // Usado em Cards e Dialogs
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: surfaceColor,
      primary: primaryColor,
      secondary: AppColors.accentColor,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor, // Cor do texto e ícones da AppBar
      elevation: 0,
      centerTitle: true,
      titleTextStyle: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    ),

    // Inputs (TextFields)
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: primaryColor),
      hintStyle: TextStyle(color: subTextColor),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: subTextColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      prefixIconColor: subTextColor,
      suffixIconColor: subTextColor,
    ),

    textTheme: baseTextTheme.apply(fontSizeFactor: fontSizeFactor),
    useMaterial3: true,
  );
}