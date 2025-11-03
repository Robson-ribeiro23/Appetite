// lib/views/provisioningscreen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/provisioningcontroller.dart';

class ProvisioningScreen extends StatelessWidget {
  const ProvisioningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Inicial do Wi-Fi')),
      body: Consumer<ProvisioningController>(
        builder: (context, controller, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.message, textAlign: TextAlign.center),
                  const SizedBox(height: 40),

                  // Botão principal que inicia o processo
                  if (controller.state == ProvisioningState.initial)
                    ElevatedButton(
                      onPressed: controller.startSetup,
                      child: const Text('INICIAR CONFIGURAÇÃO'),
                    ),

                  // Tela para digitar credenciais
                  if (controller.state ==
                          ProvisioningState.userConnectingToAp ||
                      controller.state ==
                          ProvisioningState.sendingCredentials ||
                      controller.state == ProvisioningState.failure)
                    _BuildCredentialForm(controller: controller),

                  // Status de carregamento
                  if (controller.state ==
                          ProvisioningState.sendingCredentials ||
                      controller.state ==
                          ProvisioningState.waitingForWifiConnection)
                    const CircularProgressIndicator(),

                  // Volta à tela principal após sucesso
                  if (controller.state == ProvisioningState.success)
                    ElevatedButton(
                      onPressed: () {
                        // Ao terminar, o app deve voltar para o MainScreen e tentar o MQTT
                        Navigator.of(context).pop();
                      },
                      child: const Text('VOLTAR AO APP'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuildCredentialForm extends StatefulWidget {
  final ProvisioningController controller;
  const _BuildCredentialForm({required this.controller});

  @override
  State<_BuildCredentialForm> createState() => __BuildCredentialFormState();
}

class __BuildCredentialFormState extends State<_BuildCredentialForm> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.controller.state != ProvisioningState.userConnectingToAp &&
        widget.controller.state != ProvisioningState.sendingCredentials &&
        widget.controller.state != ProvisioningState.failure) {
      return const SizedBox.shrink(); // Não mostra o formulário se o estado não for o correto
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Rede do Dispositivo: ${ProvisioningController.ESP32_AP_NAME}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Insira as credenciais do seu Wi-Fi doméstico (A QUE VOCÊ QUER USAR):',
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _ssidController,
          decoration: const InputDecoration(
            labelText: 'Seu SSID (Nome da Rede)',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Senha do Wi-Fi'),
          obscureText: true,
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed:
              widget.controller.state == ProvisioningState.sendingCredentials
              ? null
              : () => widget.controller.sendWifiCredentials(
                  _ssidController.text,
                  _passwordController.text,
                ),
          child: Text(
            widget.controller.state == ProvisioningState.sendingCredentials
                ? 'ENVIANDO...'
                : 'ENVIAR CREDENCIAIS',
          ),
        ),
        if (widget.controller.state == ProvisioningState.failure)
          TextButton(
            onPressed: widget.controller.reset,
            child: const Text('Tentar Novamente'),
          ),
      ],
    );
  }
}
