import 'dart:async';
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appetite/services/esp32service.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class HomeController extends ChangeNotifier {
  final ESP32Service _service = ESP32Service();
  final HistoryController historyController;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _message = "Toque para conectar ao ESP32 (HTTP)";
  
  ConnectionStatus get status => _status;
  String get message => _message;

  // Construtor
  HomeController({required this.historyController});

  // Getter para UI
  String get connectionStatus {
    switch (_status) {
      case ConnectionStatus.connected: return "Conectado";
      case ConnectionStatus.connecting: return "Conectando...";
      case ConnectionStatus.error: return "Falha na Conexão";
      case ConnectionStatus.disconnected: return "Desconectado";
    }
  }

  // --- CONEXÃO (PING) ---
  Future<void> attemptConnection() async {
    if (_status == ConnectionStatus.connecting) return;

    _status = ConnectionStatus.connecting;
    _message = "Buscando Alimentador na rede...";
    notifyListeners();

    // Tenta "pingar" o ESP32 via HTTP
    bool success = await _service.connectToBroker();

    if (success) {
      _status = ConnectionStatus.connected;
      // CORREÇÃO AQUI: Usar ESP32Service.baseUrl em vez de _service.baseUrl
      _message = "Conectado ao IP ${ESP32Service.baseUrl}"; 
      
    } else {
      _status = ConnectionStatus.error;
      _message = "Não encontrado no IP configurado.";
      
      // CORREÇÃO AQUI TAMBÉM
      historyController.addEntry(
        type: HistoryType.error,
        description: "Falha ao conectar no IP ${ESP32Service.baseUrl}"
      );
    }
    notifyListeners();
  }

  // --- ALIMENTAÇÃO MANUAL ---
  Future<bool> manualFeed(double grams, {bool isMaintenance = false}) async {
    if (_status != ConnectionStatus.connected) {
      _message = "Erro: Não conectado ao Alimentador.";
      notifyListeners();
      return false; // Retorna falha
    }

    _message = "Enviando comando...";
    notifyListeners();

    final payload = '{"grams": ${grams.toStringAsFixed(1)}}';
    
    // Aguarda o envio
    bool success = await _service.publishCommand('manual', payload);

    if (success) {
      _message = isMaintenance 
          ? "Manutenção iniciada com sucesso!" 
          : "Comando recebido pelo Alimentador!";
      
      historyController.addEntry(
        type: HistoryType.manual,
        description: isMaintenance 
            ? "Manutenção: Preenchimento." 
            : "Alimentação manual de ${grams.toStringAsFixed(1)}g.",
        gramsDispensed: grams,
      );
    } else {
      _message = "Falha ao enviar comando. Verifique a conexão.";
      historyController.addEntry(
        type: HistoryType.error,
        description: "Falha no envio de comando manual."
      );
    }
    notifyListeners();
    return success; // Retorna se deu certo ou não
  }

  // --- MANUTENÇÃO (PREENCHER) ---
  void fillTube() {
    // 34g * 250ms = 8500ms (8.5 segundos)
    manualFeed(34.0, isMaintenance: true);
  }

  // --- ENVIAR ALARMES ---
  Future<void> sendAlarmConfiguration(String alarmsJson) async {
    if (_status != ConnectionStatus.connected) return;

    // Envia para a rota /alarms
    bool success = await _service.publishCommand('alarme', alarmsJson);

    if (success) {
      _message = "Alarmes sincronizados com o Alimentador.";
    } else {
      _message = "Erro ao sincronizar alarmes.";
    }
    notifyListeners();
  }

  void disconnect() {
    _status = ConnectionStatus.disconnected;
    _message = "Desconectado.";
    notifyListeners();
  }
}