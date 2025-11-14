// lib/controllers/homecontroller.dart

import 'dart:async';
import 'dart:convert'; // CORREÇÃO: ADICIONE NOVAMENTE para jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // CORREÇÃO: ADICIONE NOVAMENTE para kDebugMode
import 'package:appetite/services/localesp32service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class HomeController extends ChangeNotifier {
  final LocalESP32Service _service = LocalESP32Service();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _message = "Toque para conectar ao aplicativo";

  Completer<bool>? _connectionCompleter;

  ConnectionStatus get status => _status;
  String get message => _message;

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
    _listenToESP32Status();
  }

  void _listenToESP32Status() {
    _service.statusStream.listen((data) {
      final String statusFromEsp = data['status'] ?? 'offline';
      final bool motorIsRunning = data['motorIsRunning'] ?? false;
      final String esp32Ip = data['localIP'] ?? 'N/A';

      if (kDebugMode) { // kDebugMode agora definido
        print('HomeController: Status do ESP32 recebido: $statusFromEsp, Motor: $motorIsRunning, IP: $esp32Ip');
      }

      if (statusFromEsp == 'online' && (_status != ConnectionStatus.connected)) {
        _status = ConnectionStatus.connected;
        _message = "Conexão bem-sucedida! Dispositivo ONLINE (IP: $esp32Ip).";
        notifyListeners();
        if (_connectionCompleter?.isCompleted == false) {
          _connectionCompleter!.complete(true);
        }
      } else if (statusFromEsp == 'offline' && _status == ConnectionStatus.connected) {
        _status = ConnectionStatus.disconnected;
        _message = "Dispositivo offline. Tente reconectar.";
        notifyListeners();
      } else if (statusFromEsp == 'offline' && _status == ConnectionStatus.connecting) {
        _status = ConnectionStatus.error;
        _message = "Falha na conexão inicial (dispositivo offline).";
        notifyListeners();
        if (_connectionCompleter?.isCompleted == false) {
          _connectionCompleter!.complete(false);
        }
      }
    });
  }

  Future<void> attemptConnection() async {
    if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) {
      return;
    }

    _status = ConnectionStatus.connecting;
    _message = "Tentando descobrir e conectar ao alimentador...";
    notifyListeners();

    _connectionCompleter = Completer<bool>();

    bool discoverySuccess = await _service.discoverEsp32();

    if (!discoverySuccess) {
      _status = ConnectionStatus.error;
      _message = "Não foi possível encontrar o alimentador na rede. Verifique o Wi-Fi e se o ESP32 está conectado.";
      notifyListeners();
      if (_connectionCompleter?.isCompleted == false) {
        _connectionCompleter!.complete(false);
      }
      return;
    }

    _message = "Alimentador encontrado! Aguardando confirmação de status online...";
    notifyListeners();
    _service.startPollingStatus();

    try {
      bool esp32Confirmed = await _connectionCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );

      if (!esp32Confirmed) {
        _status = ConnectionStatus.error;
        _message = "Conexão com o alimentador falhou (Timeout). Dispositivo offline ou não respondeu 'online'.";
        notifyListeners();
      }
    } on TimeoutException {
      _status = ConnectionStatus.error;
      _message = "Conexão com o alimentador falhou (Timeout). Dispositivo offline ou não respondeu 'online'.";
      notifyListeners();
    } finally {
      _connectionCompleter = null;
    }
  }

  Future<void> manualFeed(double grams) async {
    if (_status != ConnectionStatus.connected) {
      _message = "Erro: Dispositivo não conectado ou offline.";
      notifyListeners();
      return;
    }

    _message = "Enviando comando de ${grams.toStringAsFixed(1)}g. Aguardando confirmação...";
    notifyListeners();

    final payload = {"grams": grams};
    bool success = await _service.publishCommand('/feed/manual', payload);

    if (success) {
      _message = "Comando de ${grams.toStringAsFixed(1)}g enviado e confirmado!";
    } else {
      _message = "Falha ao enviar comando de alimentação. Dispositivo offline ou erro.";
    }
    notifyListeners();
  }

  Future<void> sendAlarmConfiguration(String alarmsJson) async {
    if (_status != ConnectionStatus.connected) {
      // Se não conectado, a mensagem de erro é mais relevante do que uma notificação de sucesso aqui.
      // O notifyListeners() já deve ter sido chamado para o status de desconexão.
      _message = "Erro: Dispositivo não conectado. Configuração salva localmente (não enviada ao ESP32).";
      if (kDebugMode) print('HomeController: Alarme não enviado, dispositivo desconectado.');
      notifyListeners(); // Mantém esta notificação para informar o erro.
      return;
    }

    // Evita loop, verifica se a mensagem já é a de envio e não mudou nada
    String prevMessage = _message;
    _message = "Enviando configuração de alarmes para o alimentador...";
    if (prevMessage != _message) { // Notifica apenas se a mensagem realmente mudou
      notifyListeners();
    }
    if (kDebugMode) print('HomeController: Tentando enviar alarmes...');


    final payload = jsonDecode(alarmsJson) as Map<String, dynamic>; 
    bool success = await _service.publishCommand('/alarms', payload);

    if (success) {
      // Notifica APENAS se a mensagem de sucesso for diferente da anterior
      if (_message != "Configuração de alarmes enviada com sucesso.") {
        _message = "Configuração de alarmes enviada com sucesso.";
        notifyListeners();
      }
      if (kDebugMode) print('HomeController: Alarmes enviados com sucesso.');
    } else {
      // Notifica APENAS se a mensagem de falha for diferente da anterior
      if (_message != "Falha ao enviar configuração de alarmes. Dispositivo offline ou erro.") {
        _message = "Falha ao enviar configuração de alarmes. Dispositivo offline ou erro.";
        notifyListeners();
      }
      if (kDebugMode) print('HomeController: Falha ao enviar alarmes.');
    }
    // Removi o notifyListeners() incondicional aqui para evitar loops
    // Ele será chamado condicionalmente acima.
  }
  
  void disconnect() {
    _service.disconnect();
    _status = ConnectionStatus.disconnected;
    _message = "Desconectado do aplicativo.";
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}