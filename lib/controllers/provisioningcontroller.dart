// lib/controllers/provisioningcontroller.dart
import 'package:flutter/material.dart';
import 'package:appetite/services/provisioningservice.dart';

enum ProvisioningState {
  initial,
  userConnectingToAp, // Usuário deve mudar o Wi-Fi
  sendingCredentials,
  waitingForWifiConnection, // ESP32 está tentando conectar ao Wi-Fi doméstico
  success,
  failure,
}

class ProvisioningController extends ChangeNotifier {
  final ProvisioningService _service = ProvisioningService();
  ProvisioningState _state = ProvisioningState.initial;
  String _message =
      'Bem-vindo! Para começar, prepare as credenciais do seu Wi-Fi doméstico.';

  ProvisioningState get state => _state;
  String get message => _message;

  // Nome da rede que o ESP32 deve criar
  static const String ESP32_AP_NAME = 'Appetite_SETUP';

  void startSetup() {
    _state = ProvisioningState.userConnectingToAp;
    _message =
        '1. Desconecte o Wi-Fi atual e conecte-se à rede "${ESP32_AP_NAME}".';
    notifyListeners();
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    _state = ProvisioningState.sendingCredentials;
    _message =
        '2. Enviando credenciais do Wi-Fi doméstico para o dispositivo...';
    notifyListeners();

    bool success = await _service.sendCredentials(ssid, password);

    if (success) {
      _state = ProvisioningState.waitingForWifiConnection;
      _message =
          '3. Credenciais enviadas! Aguarde 10 segundos para que o dispositivo se conecte à sua rede Wi-Fi...';
      notifyListeners();

      // Simula o tempo que o ESP32 leva para reiniciar e conectar
      await Future.delayed(const Duration(seconds: 10));

      // O App precisa tentar se conectar ao Broker MQTT (lógica que deve ser chamada após o delay)
      // O App fará a transição para a tela Home e tentará o MQTT.
      _state = ProvisioningState.success;
      _message = 'Configuração concluída! Voltando para a tela principal.';
      notifyListeners();
    } else {
      _state = ProvisioningState.failure;
      _message =
          'Falha ao enviar credenciais. Verifique se o celular está conectado à rede ${ESP32_AP_NAME}.';
      notifyListeners();
    }
  }

  void reset() {
    _state = ProvisioningState.initial;
    _message = 'Inicie a configuração novamente.';
    notifyListeners();
  }
}
