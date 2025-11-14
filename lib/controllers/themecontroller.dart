// lib/controllers/themecontroller.dart
import 'package:flutter/material.dart';
import 'package:appetite/core/constants/app_colors.dart'; // Certifique-se de que este caminho está correto

class ThemeController extends ChangeNotifier {
  // --- Propriedades de Cor e Tamanho existentes ---
  Color _primaryColor = AppColors.primaryColor;
  double _fontSizeFactor = 1.0;

  Color get primaryColor => _primaryColor;
  double get fontSizeFactor => _fontSizeFactor;

  void setPrimaryColor(Color color) {
    if (_primaryColor != color) {
      _primaryColor = color;
      notifyListeners();
    }
  }

  void setFontSizeFactor(double factor) {
    if (_fontSizeFactor != factor) {
      _fontSizeFactor = factor;
      notifyListeners();
    }
  }

  // --- NOVA PROPRIEDADE PARA MODO DE TEMA (CLARO/ESCURO) ---
  ThemeMode _themeMode = ThemeMode.dark; // Inicia como tema escuro

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notifica que o modo de tema mudou
  }
  // --------------------------------------------------------
}