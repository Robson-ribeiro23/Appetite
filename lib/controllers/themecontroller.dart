// lib/controllers/theme_controller.dart
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  // Cor primária inicial
  Color _primaryColor = Colors.blue;
  
  // Tamanho do texto inicial
  double _fontSizeFactor = 1.0; 

  Color get primaryColor => _primaryColor;
  double get fontSizeFactor => _fontSizeFactor;

  // Método para mudar a cor (será chamado pelo painel RGB)
  void setPrimaryColor(Color newColor) {
    _primaryColor = newColor;
    notifyListeners();
  }
  
  // Método para mudar o tamanho dos componentes/texto
  void setFontSizeFactor(double newFactor) {
    _fontSizeFactor = newFactor;
    notifyListeners();
  }
}