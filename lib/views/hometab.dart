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
    // Tenta conectar assim que a tela é carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeController>(context, listen: false).attemptConnection();
    });
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  // Lógica para alimentar e mostrar feedback
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

    // CORREÇÃO CRÍTICA: 
    // A verificação de "pode alimentar" agora usa o Enum 'status' (o estado real),
    // e não a String 'message' (que muda para "Comando enviado...").
    // Isso corrige o bug de "travamento" do botão.
    if (controller.status == ConnectionStatus.connected) {
      controller.manualFeed(grams);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comando de alimentação de $grams gramas enviado com sucesso!',
          ),
        ),
      );
      _gramsController.clear();
    } else {
      // Esta mensagem agora só aparece se o MQTT realmente cair
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
    final themeController = Provider.of<ThemeController>(context);

    return Consumer<HomeController>(
      builder: (context, controller, child) {
        
        // Usamos o Enum para lógica e a String 'message' para exibição
        final statusEnum = controller.status;
        final statusMessage = controller.message; 
        
        // A UI agora é habilitada pelo Enum 'status', não pela 'message'
        final isConnected = (statusEnum == ConnectionStatus.connected);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === NOVA ÁREA DE STATUS DINÂMICA ===
                _buildDynamicStatusUI(context, statusEnum, statusMessage, themeController.primaryColor),

                const SizedBox(height: 32),

// --- NOVA ÁREA: PREENCHIMENTO / MANUTENÇÃO ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15), // Fundo alaranjado para atenção
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.orange, 
                                  fontWeight: FontWeight.bold
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Se você acabou de abastecer o reservatório, pressione abaixo para alinhar a ração no tubo.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isConnected 
                              ? () => controller.fillTube() // Chama a nova função
                              : null,
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
                // === UI PARA ALIMENTAÇÃO MANUAL ===
                Text(
                  'Alimentação Manual',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Campo de entrada para gramas
                TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de Ração (gramas)',
                    hintText: 'Ex: 5.0',
                    border: OutlineInputBorder(),
                  ),
                  enabled: isConnected, // Habilitado pelo Enum
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Botão de Alimentar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConnected // Habilitado pelo Enum
                        ? () => _performManualFeed(controller)
                        : null, 
                    icon: const Icon(Icons.send),
                    label: const Text('Alimentar Agora'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: Colors.black,
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

  // NOVO WIDGET: Status de Conexão Amigável
  Widget _buildDynamicStatusUI(BuildContext context, ConnectionStatus status, String message, Color themeColor) {
    IconData icon;
    Color color;
    String friendlyMessage;
    bool showConfigButton = false;

    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.cloud_done_rounded;
        color = Colors.green;
        friendlyMessage = "Dispositivo Online";
        break;
      case ConnectionStatus.connecting:
        icon = Icons.cloud_sync_rounded;
        color = Colors.orange;
        friendlyMessage = "Conectando...";
        break;
      case ConnectionStatus.error:
        icon = Icons.cloud_off_rounded;
        color = Colors.red;
        friendlyMessage = "Dispositivo Offline";
        showConfigButton = true;
        break;
      case ConnectionStatus.disconnected:
      default:
        icon = Icons.cloud_off_rounded;
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message, // A mensagem técnica (ex: "Aguardando ESP32...")
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          
          // Botão de Configuração/Reconexão
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
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
        ],
      ),
    );
  }
}