// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers (Lógica) - Adaptado aos seus nomes de arquivo
import 'package:appetite/controllers/themecontroller.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/controllers/homecontroller.dart'; 
import 'package:appetite/controllers/historycontroller.dart'; 

// Core (Tema)
import 'package:appetite/core/theme/apptheme.dart'; // Adaptado

// Views (Interface)
import 'package:appetite/views/mainscreen.dart'; // Adaptado

void main() {
  // 1. Inicializa o gerenciamento de estado (Controllers)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AlarmController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => HistoryController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Escuta as mudanças de tema e tamanho
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'Appetite',
      debugShowCheckedModeBanner: false,
      
      // 3. Aplica o tema dinâmico (cor e tamanho)
      theme: buildAppTheme(
        themeController.primaryColor,
        themeController.fontSizeFactor, 
      ),
      
      // 4. Chama a tela principal
      // REMOVEMOS O 'const' AQUI, pois o ThemeData é dinâmico, o que quebra o const
      home: MainScreen(), 
    );
  }
}