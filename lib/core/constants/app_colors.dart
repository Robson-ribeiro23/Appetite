// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF00ADB5);
  static const Color accentColor = Color(0xFFEEEEEE);
  static const Color darkBackground = Color(0xFF222831);
  static const Color lightBackground = Color(0xFFF0F0F0);

  // Função auxiliar para gerar um MaterialColor a partir de uma cor única
  // CORREÇÃO: Usando a sugestão explícita do linter para as propriedades r, g, b
  static Map<int, Color> getMaterialColorMap(Color color) {
    // Acessa os componentes R, G, B como double (0.0 a 1.0)
    // Multiplica por 255.0, arredonda, e garante que esteja dentro de 0-255
    int redComponent = (color.red * 255.0).round().clamp(0, 255);
    int greenComponent = (color.green * 255.0).round().clamp(0, 255);
    int blueComponent = (color.blue * 255.0).round().clamp(0, 255);

    return {
      50: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.1),
      100: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.2),
      200: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.3),
      300: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.4),
      400: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.5),
      500: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.6),
      600: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.7),
      700: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.8),
      800: Color.fromRGBO(redComponent, greenComponent, blueComponent, 0.9),
      900: Color.fromRGBO(redComponent, greenComponent, blueComponent, 1.0),
    };
  }
}