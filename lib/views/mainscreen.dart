// lib/views/main_screen.dart
import 'package:flutter/material.dart';
import 'package:appetite/views/widgets/bottomnavbar.dart';
import 'hometab.dart'; 
import 'historytab.dart';
import 'settingstab.dart';
// Importamos a pasta inteira para a aba de alarmes
import 'alarmtab/alarmlistview.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Começa na aba 'Alarmes' (índice 1)

  // Lista dos widgets de cada aba
  final List<Widget> _tabs = [
    const HomeTab(),      // 0: Home (Conexão ESP32)
    const AlarmListView(),// 1: Alarmes
    const HistoryTab(),   // 2: Histórico
    const SettingsTab(),  // 3: Configurações
  ];

  // Título do AppBar para cada aba
  final List<String> _titles = [
    'Appetite - Conexão',
    'Appetite - Alarmes',
    'Appetite - Histórico',
    'Appetite - Configurações',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      
      // O corpo exibe a aba selecionada
      body: _tabs[_selectedIndex], 
      
      // A barra de navegação inferior
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}