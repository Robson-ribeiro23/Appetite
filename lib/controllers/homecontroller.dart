// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import 'package:appetite/services/esp32service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class HomeController extends ChangeNotifier {
  // Instância do serviço de comunicação externa
  final ESP32Service _service = ESP32Service(); 
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _message = "Toque para conectar";

  ConnectionStatus get status => _status;
  String get message => _message;

  Future<void> attemptConnection(String address) async {
    _status = ConnectionStatus.connecting;
    _message = "Conectando ao ESP32...";
    notifyListeners();

    // Chama a lógica de conexão simulada do Service
    final success = await _service.connectToDevice(address); 

    if (success) {
      _status = ConnectionStatus.connected;
      _message = "Conexão bem-sucedida!";
    } else {
      _status = ConnectionStatus.error;
      _message = "Falha ao conectar. Tente novamente.";
    }
    notifyListeners();
  }
  
  void disconnect() {
    _service.disconnect();
    _status = ConnectionStatus.disconnected;
    _message = "Desconectado.";
    notifyListeners();
  }
}