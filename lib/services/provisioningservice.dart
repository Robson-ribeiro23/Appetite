// lib/services/provisioningservice.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProvisioningService {
  // Endereço fixo do ESP32 quando está no modo Access Point (SoftAP)
  static const String AP_URL = 'http://192.168.4.1/config';

  /// Envia o SSID e a senha do Wi-Fi doméstico do usuário para o ESP32.
  Future<bool> sendCredentials(String ssid, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AP_URL),
        // O corpo da requisição deve corresponder ao que o ESP32 espera (handleConfig)
        body: {'ssid': ssid, 'password': password},
      );

      // O ESP32 deve retornar um status 200 (OK) se receber as credenciais.
      if (response.statusCode == 200 &&
          response.body.contains("Credenciais recebidas")) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Falha de rede: geralmente significa que o celular não está conectado ao AP do ESP32
      print("Provisioning Error: $e");
      return false;
    }
  }
}
