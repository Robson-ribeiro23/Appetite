// lib/views/hometab.dart

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
        const SnackBar(content: Text('Por favor, insira uma quantidade válida de ração.')),
      );
      return;
    }

    if (controller.status == ConnectionStatus.connected) {
      controller.manualFeed(grams);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comando de alimentação de $grams gramas enviado com sucesso!')),
      );
      _gramsController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Dispositivo offline. Tente reconectar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context); // Acesso fácil ao tema atual

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
                // === STATUS DINÂMICO ===
                _buildDynamicStatusUI(context, statusEnum, statusMessage, themeController.primaryColor),

                const SizedBox(height: 32),

                // === ÁREA DE MANUTENÇÃO (PREENCHER SISTEMA) ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1), // Fundo suave adaptável
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 10),
                          Text(
                            "Manutenção",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Se você acabou de abastecer o reservatório, pressione abaixo para alinhar a ração no tubo.",
                        style: theme.textTheme.bodySmall, // Cor adaptável do tema
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isConnected ? () => controller.fillTube() : null,
                          icon: const Icon(Icons.plumbing),
                          label: const Text("PREENCHER SISTEMA (8.5s)"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // === ALIMENTAÇÃO MANUAL ===
                Text(
                  'Alimentação Manual',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeController.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de Ração (gramas)',
                    hintText: 'Ex: 5.0',
                    border: OutlineInputBorder(),
                  ),
                  enabled: isConnected,
                  // style: null (removemos o style fixo para usar o do tema)
                ),
                
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? () => _performManualFeed(controller) : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Alimentar Agora'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: Colors.white, // Texto branco no botão fica bom sempre
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final theme = Theme.of(context);
    IconData icon;
    Color statusColor;
    String friendlyMessage;
    bool showConfigButton = false;

    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.cloud_done_rounded;
        statusColor = Colors.green;
        friendlyMessage = "Dispositivo Online";
        break;
      case ConnectionStatus.connecting:
        icon = Icons.cloud_sync_rounded;
        statusColor = Colors.orange;
        friendlyMessage = "Conectando...";
        break;
      case ConnectionStatus.error:
        icon = Icons.cloud_off_rounded;
        statusColor = Colors.red;
        friendlyMessage = "Dispositivo Offline";
        showConfigButton = true;
        break;
      case ConnectionStatus.disconnected:
      default:
        icon = Icons.cloud_off_rounded;
        statusColor = Colors.grey;
        friendlyMessage = "Dispositivo Desconectado";
        showConfigButton = true;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1), // Fundo suave da cor do status
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: statusColor),
          const SizedBox(height: 16),
          Text(
            friendlyMessage,
            style: theme.textTheme.titleLarge?.copyWith(
              color: statusColor, 
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium, // Usa a cor do texto do tema (preto/branco)
            textAlign: TextAlign.center,
          ),
          
          if (showConfigButton)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Na demo, isso pode ser ignorado ou levar ao provisionamento
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProvisioningScreen()),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurar Wi-Fi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}