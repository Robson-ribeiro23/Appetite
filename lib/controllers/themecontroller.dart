import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  Color _primaryColor = Colors.blue;
  double _fontSizeFactor = 1.0;
  
  // Novo controle de Tema
  ThemeMode _themeMode = ThemeMode.dark; // Começa escuro por padrão

  Color get primaryColor => _primaryColor;
  double get fontSizeFactor => _fontSizeFactor;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setPrimaryColor(Color newColor) {
    _primaryColor = newColor;
    notifyListeners();
  }
  
  void setFontSizeFactor(double newFactor) {
    _fontSizeFactor = newFactor;
    notifyListeners();
  }

  // Alternar entre Claro e Escuro
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}