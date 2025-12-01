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
  bool _isLoading = false; // Controle do estado de carregamento

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

  // Feedback Visual de Sucesso (Dialog bonito)
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              "Sucesso!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    // Fecha sozinho após 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // Lógica para alimentar
  void _performManualFeed(HomeController controller) async {
    final gramsText = _gramsController.text;
    final grams = double.tryParse(gramsText);

    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira uma quantidade válida.')),
      );
      return;
    }

    if (controller.status == ConnectionStatus.connected) {
      setState(() => _isLoading = true); // Trava a UI e mostra loading

      // Chama a função que agora retorna Future<bool>
      bool success = await controller.manualFeed(grams);

      if (mounted) setState(() => _isLoading = false); // Destrava a UI

      if (success) {
        _showSuccessDialog('Comando de $grams g enviado!');
        _gramsController.clear();
        FocusScope.of(context).unfocus(); // Esconde o teclado
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar. Tente novamente.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo offline.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);

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
                // === STATUS DE CONEXÃO ===
                _buildDynamicStatusUI(context, statusEnum, statusMessage, themeController.primaryColor),

                const SizedBox(height: 32),

                // === ÁREA DE MANUTENÇÃO ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.build_circle_outlined, color: Colors.orange),
                          const SizedBox(width: 10),
                          Text(
                            "Manutenção",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.orange, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Use para preencher o tubo após abastecer o reservatório.",
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          // Só permite clicar se conectado e não estiver carregando outra coisa
                          onPressed: isConnected && !_isLoading 
                              ? () => controller.fillTube() 
                              : null,
                          icon: const Icon(Icons.plumbing),
                          label: const Text("PREENCHER SISTEMA"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    color: themeController.primaryColor
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade (gramas)',
                    hintText: 'Ex: 50',
                    suffixText: 'g',
                    border: OutlineInputBorder(),
                  ),
                  enabled: isConnected && !_isLoading,
                ),
                
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConnected && !_isLoading 
                        ? () => _performManualFeed(controller) 
                        : null,
                    
                    // Troca o ícone por Loading girando se estiver carregando
                    icon: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    
                    label: Text(_isLoading ? 'ENVIANDO...' : 'ALIMENTAR AGORA'),
                    
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  // Widget de Status (Cards coloridos)
  Widget _buildDynamicStatusUI(BuildContext context, ConnectionStatus status, String message, Color themeColor) {
    final theme = Theme.of(context);
    IconData icon;
    Color statusColor;
    String friendlyMessage;

    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.wifi_tethering;
        statusColor = Colors.green;
        friendlyMessage = "Conectado";
        break;
      case ConnectionStatus.connecting:
        icon = Icons.sync;
        statusColor = Colors.orange;
        friendlyMessage = "Buscando...";
        break;
      case ConnectionStatus.error:
        icon = Icons.wifi_off;
        statusColor = Colors.red;
        friendlyMessage = "Offline";
        break;
      default:
        icon = Icons.power_off;
        statusColor = Colors.grey;
        friendlyMessage = "Desconectado";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendlyMessage, 
                  style: theme.textTheme.titleLarge?.copyWith(color: statusColor, fontWeight: FontWeight.bold)
                ),
                Text(
                  message, 
                  style: theme.textTheme.bodySmall, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}