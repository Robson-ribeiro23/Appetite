// lib/services/esp32service.dart (CÓDIGO FINAL E CORRETO PARA MQTT)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class ESP32Service {
  // Configurações do Broker MQTT (Usamos um exemplo público para testes)
  static const String brokerHost = 'test.mosquitto.org';
  static const int brokerPort = 1883;
  static const String clientId = 'flutter_appetite_client';

  MqttServerClient? client;

  // Stream para enviar mensagens recebidas do ESP32 para o Controller
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  Stream<String> get messageStream =>
      _messageController.stream; // <-- DEFINIÇÃO CORRETA

  // --- 1. CONEXÃO COM O BROKER ---
  Future<bool> connectToBroker() async {
    // <-- DEFINIÇÃO CORRETA
    // Usando os nomes de constantes
    client = MqttServerClient(brokerHost, clientId);
    client!.port = brokerPort;

    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;

    try {
      final MqttConnectMessage connMess = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      client!.connectionMessage = connMess;

      await client!.connect();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Erro de Conexão MQTT: $e');
      }
      client!.disconnect();
      return false;
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      // 2. Assinar tópicos (para receber status do ESP32)
      client!.subscribe('appetite/status/#', MqttQos.atLeastOnce);

      // 3. Configurar callback para receber mensagens
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        _messageController.add(payload);

        if (kDebugMode) {
          print('MQTT Mensagem recebida no tópico ${c[0].topic}: $payload');
        }
      });

      return true;
    } else {
      return false;
    }
  }

  void onConnected() {
    if (kDebugMode) {
      print('MQTT: Conectado ao Broker!');
    }
  }

  void onDisconnected() {
    if (kDebugMode) {
      print('MQTT: Desconectado do Broker.');
    }
  }

  // --- 4. PUBLICAR COMANDOS ---
  void publishCommand(String topic, String payload) {
    // <-- DEFINIÇÃO CORRETA
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      if (kDebugMode) {
        print('MQTT: Não conectado ao Broker. Comando não enviado.');
      }
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    if (kDebugMode) {
      print('MQTT: Comando publicado para o tópico $topic');
    }
  }

  void disconnect() {
    client?.disconnect();
  }
}
