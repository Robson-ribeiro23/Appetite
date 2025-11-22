// lib/controllers/homecontroller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appetite/services/esp32service.dart';
import 'package:appetite/controllers/historycontroller.dart'; // Importe o HistoryController
import 'package:appetite/models/historyentrymodel.dart';   // Importe o Modelo

enum ConnectionStatus { disconnected, connecting, connected, error }

class HomeController extends ChangeNotifier {
  final ESP32Service _service = ESP32Service();
  
  // --- NOVA DEPENDÊNCIA ---
  final HistoryController historyController; 

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _message = "Toque para conectar ao Broker MQTT";
  Completer<bool>? _connectionCompleter;
  String _alarmPayload = '[]';

  ConnectionStatus get status => _status;
  String get message => _message;

  String get connectionStatus {
    switch (_status) {
      case ConnectionStatus.connected: return "Conectado";
      case ConnectionStatus.connecting: return "Conectando...";
      case ConnectionStatus.error: return "Falha na Conexão";
      case ConnectionStatus.disconnected: return "Desconectado";
    }
  }

  // --- CONSTRUTOR ATUALIZADO ---
  // Agora exigimos o historyController ao criar este controller
  HomeController({required this.historyController}) {
    _listenToBrokerMessages();
  }

  void _listenToBrokerMessages() {
    _service.messageStream.listen((payload) {
      if (payload == 'online') {
        if (_status != ConnectionStatus.connected) {
          _status = ConnectionStatus.connected;
          _message = "Conexão bem-sucedida! Dispositivo ONLINE.";
          notifyListeners();
        }
        if (_connectionCompleter?.isCompleted == false) {
          _connectionCompleter!.complete(true);
        }
        return;
      }

      if (payload.contains('success')) {
        _message = "Dispensa concluída com sucesso!";
        notifyListeners();
      }
    });
  }

  Future<void> attemptConnection() async {
    if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) {
      return;
    }

    _status = ConnectionStatus.connecting;
    _message = "Conectando ao Broker MQTT...";
    notifyListeners();

    bool brokerSuccess = await _service.connectToBroker();

    if (!brokerSuccess) {
      _status = ConnectionStatus.error;
      _message = "Falha ao conectar ao Broker MQTT. Verifique sua rede.";
      
      // --- REGISTRO DE ERRO NO HISTÓRICO ---
      historyController.addEntry(
        type: HistoryType.error, 
        description: "Falha de conexão com Broker MQTT."
      );
      
      notifyListeners();
      return;
    }

    _message = "Conexão com Broker OK. Aguardando ESP32 (10s)...";
    notifyListeners();

    _connectionCompleter = Completer<bool>();

    try {
      bool esp32Confirmed = await _connectionCompleter!.future.timeout(
        const Duration(seconds: 15), // Aumentei um pouco o timeout por segurança
        onTimeout: () => false,
      );

      if (!esp32Confirmed) {
        _status = ConnectionStatus.error;
        _message = "Conexão com ESP32 falhou (Timeout). Dispositivo offline.";
        
        // --- REGISTRO DE ERRO NO HISTÓRICO ---
        historyController.addEntry(
          type: HistoryType.error, 
          description: "Timeout: ESP32 não respondeu."
        );
        
        notifyListeners();
      }
    } on TimeoutException {
      _status = ConnectionStatus.error;
      _message = "Conexão com ESP32 falhou (Timeout). Dispositivo offline.";
      notifyListeners();
    } finally {
      _connectionCompleter = null;
    }
  }

  // Função para preencher o tubo (8.5 segundos)
  void fillTube() {
    if (_status != ConnectionStatus.connected) {
      _message = "Erro: Conecte-se antes de realizar manutenção.";
      notifyListeners();
      return;
    }

    const double gramsForFill = 34.0;
    manualFeed(gramsForFill, isMaintenance: true); // Flag para diferenciar no histórico
  }

  void manualFeed(double grams, {bool isMaintenance = false}) {
    if (_status != ConnectionStatus.connected) {
      _message = "Erro: Dispositivo não conectado ou offline.";
      notifyListeners();
      return;
    }

    final payload = '{"command": "feed_manual", "grams": ${grams.toStringAsFixed(1)}}';
    _service.publishCommand('appetite/comando/manual', payload);

    _message = isMaintenance 
        ? "Preenchendo sistema..." 
        : "Comando de ${grams.toStringAsFixed(1)}g enviado. Aguardando confirmação...";
    
    // --- REGISTRO DE AÇÃO NO HISTÓRICO ---
    historyController.addEntry(
      type: HistoryType.manual,
      description: isMaintenance 
          ? "Manutenção: Preenchimento do tubo." 
          : "Alimentação manual de ${grams.toStringAsFixed(1)}g.",
      gramsDispensed: grams,
    );

    notifyListeners();
  }

  void sendAlarmConfiguration(String alarmsJson) {
    if (_status != ConnectionStatus.connected) {
      _message = "Erro: Aplicativo não conectado ao Broker. Configuração salva localmente.";
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