// lib/controllers/homecontroller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appetite/services/esp32service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class HomeController extends ChangeNotifier {
  final ESP32Service _service = ESP32Service();
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _message = "Toque para conectar ao Broker MQTT";

  // Completer usado para forçar a função de conexão a esperar a confirmação do ESP32
  Completer<bool>? _connectionCompleter;
  String _alarmPayload = '[]';

  ConnectionStatus get status => _status;
  String get message => _message;

  // Getter de status para compatibilidade com a HomeTab (retorna a string correta)
  String get connectionStatus {
    switch (_status) {
      case ConnectionStatus.connected:
        return "Conectado";
      case ConnectionStatus.connecting:
        return "Conectando...";
      case ConnectionStatus.error:
        return "Falha na Conexão";
      case ConnectionStatus.disconnected:
        return "Desconectado";
    }
  }

  HomeController() {
    _listenToBrokerMessages();
  }

  // --- ESCUTA DE MENSAGENS DO BROKER ---
  void _listenToBrokerMessages() {
    _service.messageStream.listen((payload) {
      // 1. A ESP32 envia a mensagem "online"
      if (payload == 'online') {
        // Se a mensagem 'online' chegar e o status ainda não for conectado, atualiza
        if (_status != ConnectionStatus.connected) {
          _status = ConnectionStatus.connected;
          _message = "Conexão bem-sucedida! Dispositivo ONLINE.";
          notifyListeners();
        }

        // 2. Resolve o Completer que estava esperando
        if (_connectionCompleter?.isCompleted == false) {
          _connectionCompleter!.complete(true);
        }
        return;
      }

      // ... (Lógica de tratamento para outras mensagens: confirmação de dispensa, etc.)
      if (payload.contains('success')) {
        _message = "Dispensa concluída com sucesso!";
        notifyListeners();
      }
    });
  }

  // --- LÓGICA DE CONEXÃO COM ESPERA E TIMEOUT ---
  Future<void> attemptConnection() async {
    if (_status == ConnectionStatus.connecting ||
        _status == ConnectionStatus.connected) {
      return;
    }

    _status = ConnectionStatus.connecting;
    _message = "Conectando ao Broker MQTT...";
    notifyListeners();

    // 1. Conecta ao Broker
    bool brokerSuccess = await _service.connectToBroker();

    if (!brokerSuccess) {
      _status = ConnectionStatus.error;
      _message = "Falha ao conectar ao Broker MQTT. Verifique sua rede.";
      notifyListeners();
      return;
    }

    // 2. Conexão com Broker OK. Agora, espera pela mensagem 'online' do ESP32
    _message = "Conexão com Broker OK. Aguardando ESP32 (10s)...";
    notifyListeners();

    _connectionCompleter = Completer<bool>();

    try {
      // 3. Espera pela confirmação do ESP32, com limite de 10 segundos
      bool esp32Confirmed = await _connectionCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );

      if (!esp32Confirmed) {
        _status = ConnectionStatus.error;
        _message = "Conexão com ESP32 falhou (Timeout). Dispositivo offline.";
        notifyListeners();
      }
    } on TimeoutException {
      _status = ConnectionStatus.error;
      _message = "Conexão com ESP32 falhou (Timeout). Dispositivo offline.";
      notifyListeners();
    } finally {
      // Limpa o Completer para a próxima tentativa
      _connectionCompleter = null;
    }
  }

  void manualFeed(double grams) {
    if (_status != ConnectionStatus.connected) {
      _message = "Erro: Dispositivo não conectado ou offline.";
      notifyListeners();
      return;
    }

    final payload =
        '{"command": "feed_manual", "grams": ${grams.toStringAsFixed(1)}}';
    _service.publishCommand('appetite/comando/manual', payload);

    _message =
        "Comando de ${grams.toStringAsFixed(1)}g enviado. Aguardando confirmação...";
    notifyListeners();
  }

  void sendAlarmConfiguration(String alarmsJson) {
    if (_status != ConnectionStatus.connected) {
      _message =
          "Erro: Aplicativo não conectado ao Broker. Configuração salva localmente.";
      notifyListeners();
      return;
    }

    _alarmPayload = alarmsJson;
    _service.publishCommand('appetite/comando/alarme', _alarmPayload);

    _message = "Configuração de alarmes enviada com sucesso.";
    notifyListeners();
  }

  void disconnect() {
    _service.disconnect();
    _status = ConnectionStatus.disconnected;
    _message = "Desconectado do Broker.";
    notifyListeners();
  }
}
