// lib/services/localesp32service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Correção: AGORA EXISTE
import 'package:flutter/material.dart'; // ADICIONADO para herdar de ChangeNotifier

// A classe LocalESP32Service agora herda de ChangeNotifier
class LocalESP32Service extends ChangeNotifier { 
  String? _esp32IpAddress;
  static const String _esp32IpKey = 'esp32_local_ip';

  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  Timer? _statusPollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);

  LocalESP32Service() {
    _loadIpAddress();
  }

  Future<void> _loadIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _esp32IpAddress = prefs.getString(_esp32IpKey);
    if (kDebugMode && _esp32IpAddress != null) {
      print('LocalESP32Service: IP do ESP32 carregado: $_esp32IpAddress');
    }
  }

  Future<void> _saveIpAddress(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_esp32IpKey, ip);
    _esp32IpAddress = ip;
    if (kDebugMode) {
      print('LocalESP32Service: IP do ESP32 salvo: $_esp32IpAddress');
    }
  }

  void startPollingStatus() {
    if (_statusPollingTimer != null && _statusPollingTimer!.isActive) return;

    _statusPollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      await fetchStatus();
    });
    if (kDebugMode) {
      print('LocalESP32Service: Iniciando polling de status.');
    }
  }

  void stopPollingStatus() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    if (kDebugMode) {
      print('LocalESP32Service: Parando polling de status.');
    }
  }

Future<bool> discoverEsp32() async {
    if (_esp32IpAddress != null) {
      if (kDebugMode) {
        print('LocalESP32Service: Tentando IP salvo: $_esp32IpAddress');
      }
      try {
        final response = await http.get(Uri.parse('http://$_esp32IpAddress/status')).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          _statusController.add(jsonDecode(response.body));
          if (kDebugMode) {
            print('LocalESP32Service: ESP32 encontrado no IP salvo: $_esp32IpAddress');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('LocalESP32Service: Falha com IP salvo $_esp32IpAddress. Erro: $e');
        }
        _esp32IpAddress = null; // Limpa o IP salvo se ele não funciona mais
      }
    }

    if (kDebugMode) {
      print('LocalESP32Service: Tentando descobrir IP do ESP32 na rede local...');
    }

    // LISTA DE PREFIXOS DE REDE A SEREM TESTADOS
    // Adicione o prefixo da sua rede aqui!
    List<String> ipPrefixesToScan = [
      '10.41.221.', // O prefixo da SUA rede, conforme o log do ESP32
      '192.168.1.',
      '192.168.0.',
      // Adicione outros prefixos comuns se necessário, ex: '172.16.0.'
    ];

    for (String prefix in ipPrefixesToScan) {
      for (int i = 1; i < 255; i++) {
        final testIp = '$prefix$i';
        try {
          // Ajustei o timeout para 1 segundo, para não demorar demais
          final response = await http.get(Uri.parse('http://$testIp/status')).timeout(const Duration(milliseconds: 1000));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            // Verifica se a resposta contém a chave 'status' e se ela é 'online'
            if (data.containsKey('status') && data['status'] == 'online') {
              await _saveIpAddress(testIp);
              _statusController.add(data);
              if (kDebugMode) {
                print('LocalESP32Service: ESP32 descoberto em $testIp');
              }
              return true;
            }
          }
        } catch (e) {
          // Ignora erros de conexão para IPs que não respondem.
          // Se quiser ver quais IPs estão falhando, descomente a linha abaixo:
          // if (kDebugMode) print('LocalESP32Service: Falha ao conectar em $testIp: $e');
        }
      }
    }

    if (kDebugMode) {
      print('LocalESP32Service: Não foi possível descobrir o IP do ESP32 após varredura.');
    }
    return false;
  }

  Future<bool> fetchStatus() async {
    if (_esp32IpAddress == null) {
      if (kDebugMode) {
        print('LocalESP32Service: IP do ESP32 não definido. Não pode buscar status.');
      }
      _statusController.add({'status': 'offline', 'message': 'IP do ESP32 desconhecido.'});
      return false;
    }

    try {
      final response = await http.get(Uri.parse('http://$_esp32IpAddress/status')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _statusController.add(data);
        return true;
      } else {
        if (kDebugMode) {
          print('LocalESP32Service: Erro ao buscar status. Status: ${response.statusCode}');
        }
        _statusController.add({'status': 'offline', 'message': 'Erro HTTP: ${response.statusCode}'});
        return false;
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('LocalESP32Service: Erro de rede ao buscar status: $e');
      }
      _statusController.add({'status': 'offline', 'message': 'Erro de rede ou dispositivo offline.'});
      return false;
    } on TimeoutException {
      if (kDebugMode) {
        print('LocalESP32Service: Timeout ao buscar status.');
      }
      _statusController.add({'status': 'offline', 'message': 'Timeout: dispositivo não responde.'});
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('LocalESP32Service: Erro desconhecido ao buscar status: $e');
      }
      _statusController.add({'status': 'offline', 'message': 'Erro inesperado.'});
      return false;
    }
  }

  Future<bool> publishCommand(String endpoint, Map<String, dynamic> payload) async {
    if (_esp32IpAddress == null) {
      if (kDebugMode) {
        print('LocalESP32Service: IP do ESP32 não definido. Comando não enviado.');
      }
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$_esp32IpAddress$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('LocalESP32Service: Comando enviado com sucesso para $endpoint');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('LocalESP32Service: Erro ao enviar comando para $endpoint. Status: ${response.statusCode}, Body: ${response.body}');
        }
        return false;
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('LocalESP32Service: Erro de rede ao enviar comando para $endpoint: $e');
      }
      return false;
    } on TimeoutException {
      if (kDebugMode) {
        print('LocalESP32Service: Timeout ao enviar comando para $endpoint.');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('LocalESP32Service: Erro desconhecido ao enviar comando para $endpoint: $e');
      }
      return false;
    }
  }

  void disconnect() {
    stopPollingStatus();
    _esp32IpAddress = null;
    if (kDebugMode) {
      print('LocalESP32Service: Desconectado.');
    }
  }

  @override // Agora, @override é válido porque herda de ChangeNotifier
  void dispose() {
    _statusController.close();
    stopPollingStatus();
    super.dispose(); // Chama o dispose da superclasse ChangeNotifier
  }
}