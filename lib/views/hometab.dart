// lib/views/hometab.dart (IU AMIGÁVEL E CORRIGIDA)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/views/widgets/provisioningscreen.dart'; 
import 'package:appetite/controllers/themecontroller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _gramsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeController>(context, listen: false).attemptConnection();
    });
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _performManualFeed(HomeController controller) {
    final gramsText = _gramsController.text;
    final grams = double.tryParse(gramsText);

    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma quantidade válida de ração.'),
        ),
      );
      return;
    }

    if (controller.status == ConnectionStatus.connected) {
      controller.manualFeed(grams);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comando de alimentação de $grams gramas enviado!', // Mensagem atualizada
          ),
        ),
      );
      _gramsController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro: Dispositivo offline. Tente reconectar.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(context);

    return Consumer<HomeController>(
      builder: (context, controller, child) {
        
        final statusEnum = controller.status;
        final statusMessage = controller.message; 
        
        final isConnected = (statusEnum == ConnectionStatus.connected);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDynamicStatusUI(context, statusEnum, statusMessage, themeController.primaryColor),

                const SizedBox(height: 32),

                Text(
                  'Alimentação Manual',
                  style: theme.textTheme.headlineSmall, 
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration( 
                    labelText: 'Quantidade de Ração (gramas)',
                    hintText: 'Ex: 5.0',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color), 
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)), 
                  ),
                  enabled: isConnected,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color), 
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConnected
                        ? () => _performManualFeed(controller)
                        : null, 
                    icon: const Icon(Icons.send),
                    label: const Text('Alimentar Agora'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary, 
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicStatusUI(BuildContext context, ConnectionStatus status, String message, Color themeColor) {
    IconData icon;
    Color color;
    String friendlyMessage;
    bool showConfigButton = false;
    final theme = Theme.of(context);

    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.wifi_rounded; // Ícone de Wi-Fi para conexão local
        color = Colors.green;
        friendlyMessage = "Dispositivo Online";
        break;
      case ConnectionStatus.connecting:
        icon = Icons.wifi_find_rounded;
        color = Colors.orange;
        friendlyMessage = "Conectando...";
        break;
      case ConnectionStatus.error:
        icon = Icons.wifi_off_rounded;
        color = Colors.red;
        friendlyMessage = "Dispositivo Offline";
        showConfigButton = true;
        break;
      case ConnectionStatus.disconnected:
      default:
        icon = Icons.wifi_off_rounded;
        color = Colors.grey;
        friendlyMessage = "Dispositivo Desconectado";
        showConfigButton = true;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 16),
          Text(
            friendlyMessage,
            style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message, // A mensagem técnica (ex: "Aguardando ESP32...")
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)), 
            textAlign: TextAlign.center,
          ),
          
          if (showConfigButton)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProvisioningScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurar/Reconfigurar Wi-Fi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: theme.colorScheme.onPrimary, 
                  textStyle: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
        ],
      ),
    );
  }
}