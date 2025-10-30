// lib/views/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.router), // Ícone para conexão (ex: roteador, IoT)
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.alarm),
          label: 'Alarmes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Histórico',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configurações',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Theme.of(context).primaryColor, // Usa a cor dinâmica
      unselectedItemColor: Colors.grey,
      onTap: onItemSelected,
      type: BottomNavigationBarType.fixed, // Garante que todos os itens são visíveis
      backgroundColor: Colors.black, // Cor de fundo para combinar com o tema escuro
    );
  }
}