import 'dart:async';
//import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ESP32Service {
  // --- CONFIGURAÇÃO CRÍTICA  ---
  // 1. Ligue o Hotspot do Celular.
  // 2. Ligue o ESP32 e olhe no Monitor Serial qual IP ele pegou.
  // 3. Escreva o IP aqui embaixo antes de rodar o app.
  static const String espIp = "10.229.21.102"; 
  
  static const String baseUrl = "http://$espIp";


  Stream<String> get messageStream => const Stream.empty();

  // --- 1. TESTAR CONEXÃO (PING) ---
  Future<bool> connectToBroker() async {

    try {
      if (kDebugMode) print('Tentando contactar o ESP32 em $baseUrl/status ...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/status')
      ).timeout(const Duration(seconds: 3)); // Timeout curto para ser ágil

      if (response.statusCode == 200) {
        if (kDebugMode) print('ESP32 respondeu! Estamos conectados.');
        return true;
      } else {
        if (kDebugMode) print('ESP32 respondeu com erro: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Falha ao conectar no IP $espIp: $e');
      return false;
    }
  }

  // --- 2. ENVIAR COMANDOS ---

  Future<bool> publishCommand(String topic, String jsonPayload) async {
    String endpoint = "";
    
    // Mapeia os tópicos antigos do MQTT para rotas HTTP
    if (topic.contains("manual")) {
      endpoint = "/manual";
    } else if (topic.contains("alarme")) {
      endpoint = "/alarms";
    } else {
      return false;
    }

    try {
      if (kDebugMode) print('Enviando POST para $baseUrl$endpoint com: $jsonPayload');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonPayload,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (kDebugMode) print('Comando enviado com sucesso!');
        return true;
      } else {
        if (kDebugMode) print('Erro no ESP32: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Erro de envio HTTP: $e');
      return false;
    }
  }

  void disconnect() {
    // HTTP não precisa desconectar
  }
}