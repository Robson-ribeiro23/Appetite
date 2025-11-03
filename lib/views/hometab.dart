// lib/views/hometab.dart (CÓDIGO FINAL COM LÓGICA DE PROVISIONAMENTO)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/views/widgets/provisioningscreen.dart'; // NOVO: Tela de Configuração Wi-Fi

// Importe AppColors e ThemeController para acessar a cor primária global
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
    // Tenta conectar logo que a tela é carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeController>(context, listen: false).attemptConnection();
    });
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  // Função utilitária para obter a cor do status (baseada na STRING de status)
  Color _getStatusColor(String statusMessage) {
    if (statusMessage.contains("Conectado")) return Colors.green;
    if (statusMessage.contains("Conectando")) return Colors.orange;
    if (statusMessage.contains("Falha") || statusMessage.contains("Timeout"))
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

    // Ação: Se a conexão estiver OK, envie o comando.
    if (controller.message.contains("Conectado")) {
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
            'Erro: Dispositivo offline. Tente configurar ou reconectar.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acessamos o tema dinâmico para estilização
    final themeController = Provider.of<ThemeController>(context);

    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final statusMessage =
            controller.message; // Usamos a mensagem completa do Controller
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
                      // Adiciona Expanded para evitar overflow de texto
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
                      // Se a conexão MQTT falhar ou estiver desconectada, inicie o Provisionamento
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProvisioningScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurar/Reconfigurar Wi-Fi'),
                    style: ElevatedButton.styleFrom(
                      // Usa a cor primária do tema para o botão de setup
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
