// lib/views/hometab.dart (CÓDIGO FINAL E CORRIGIDO)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/views/widgets/provisioningscreen.dart'; // Import corrigido
import 'package:appetite/core/constants/appcolors.dart';
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

  Color _getStatusColor(String statusMessage) {
    if (statusMessage.contains("Dispositivo ONLINE") ||
        statusMessage.contains("Conexão bem-sucedida"))
      return Colors.green;
    if (statusMessage.contains("Conectando")) return Colors.orange;
    if (statusMessage.contains("Falha") ||
        statusMessage.contains("Timeout") ||
        statusMessage.contains("offline"))
      return Colors.red;
    return Colors.grey;
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

    // CORREÇÃO: Checamos agora se a mensagem contém a chave de sucesso.
    final bool canFeed = controller.message.contains("Dispositivo ONLINE");

    if (canFeed) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: Dispositivo offline. Status atual: ${controller.message}.',
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
        final statusMessage = controller.message;
        final statusColor = _getStatusColor(statusMessage);

        // Determina se a UI de alimentação deve estar ativa
        final isConnected =
            statusMessage.contains("Conexão bem-sucedida") ||
            statusMessage.contains("Dispositivo ONLINE");

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === ÁREA DE STATUS DA CONEXÃO ===
                Row(
                  children: [
                    Text(
                      'Status MQTT: ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    CircleAvatar(radius: 5, backgroundColor: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botão de Configuração/Reconexão
                if (!isConnected) // Se não estiver conectado, mostra o botão de ajuda
                  ElevatedButton.icon(
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
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                  ),

                const SizedBox(height: 32),

                // === UI PARA ALIMENTAÇÃO MANUAL ===
                Text(
                  'Alimentação Manual',
                  style: Theme.of(context).textTheme.headlineSmall,
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
                  // Desabilita se não estiver conectado
                  enabled: isConnected,
                ),
                const SizedBox(height: 16),

                // Botão de Alimentar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConnected
                        ? () => _performManualFeed(controller)
                        : null, // Desabilita o botão se não estiver conectado
                    icon: const Icon(Icons.send),
                    label: const Text('Alimentar Agora'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      // Usa a cor primária do tema
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: Colors.black,
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
}
