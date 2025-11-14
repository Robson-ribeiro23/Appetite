// lib/controllers/provisioningcontroller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appetite/services/provisioningservice.dart';
import 'package:appetite/controllers/homecontroller.dart'; 
import 'package:appetite/services/localesp32service.dart'; // ADICIONE esta importação

enum ProvisioningState {
  initial,
  userConnectingToAp, 
  sendingCredentials,
  waitingForWifiConnection, 
  success,
  failure,
}

class ProvisioningController extends ChangeNotifier {
  final ProvisioningService _service = ProvisioningService();
  final LocalESP32Service _localEsp32Service = LocalESP32Service(); // Instância do novo serviço local

  ProvisioningState _state = ProvisioningState.initial;
  String _message = 'Bem-vindo! Para começar, prepare as credenciais do seu Wi-Fi doméstico.';
  
  final HomeController homeController;

  ProvisioningController({required this.homeController});

  ProvisioningState get state => _state;
  String get message => _message;

  static const String ESP32_AP_NAME = 'Appetite_SETUP'; 

  void startSetup() {
    _state = ProvisioningState.userConnectingToAp;
    _message = '1. Desconecte o Wi-Fi atual e conecte-se à rede "${ESP32_AP_NAME}".';
    notifyListeners();
  }

  Future<void> sendWifiCredentials(String ssid, String password) async {
    _state = ProvisioningState.sendingCredentials;
    _message = '2. Enviando credenciais do Wi-Fi doméstico para o dispositivo...';
    notifyListeners();

    bool success = await _service.sendCredentials(ssid, password);

    if (success) {
      _state = ProvisioningState.waitingForWifiConnection;
      _message = '3. Credenciais enviadas! Aguarde o dispositivo reiniciar e conectar à sua rede...';
      notifyListeners();
      
      // Simula o tempo que o ESP32 leva para reiniciar e conectar
      // Agora, esperamos que o ESP32 apareça na rede local.
      await Future.delayed(const Duration(seconds: 5)); // Pequeno delay antes de tentar descobrir

      // Tenta descobrir o ESP32 na rede local após ele ter se conectado
      bool esp32Found = await _localEsp32Service.discoverEsp32(); // Usando o novo serviço

      if (esp32Found) {
        _state = ProvisioningState.success;
        _message = 'Configuração concluída! Dispositivo conectado à sua rede.';
        notifyListeners();

        // CRÍTICO: Dispara a conexão/descoberta HTTP remota após o provisionamento
        homeController.attemptConnection(); 
      } else {
        _state = ProvisioningState.failure;
        _message = 'Falha: Dispositivo enviou credenciais mas não foi encontrado na sua rede doméstica. Verifique o Wi-Fi e tente novamente.';
        notifyListeners();
      }
      
    } else {
      _state = ProvisioningState.failure;
      _message = 'Falha ao enviar credenciais. Verifique se o celular ainda está conectado à rede "${ESP32_AP_NAME}".';
      notifyListeners();
    }
  }

  void reset() {
    _state = ProvisioningState.initial;
    _message = 'Inicie a configuração novamente.';
    notifyListeners();
  }
}