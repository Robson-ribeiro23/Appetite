// lib/controllers/alarmcontroller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:appetite/services/notification_service.dart';

class AlarmController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  Timer? _timer;

  final HomeController homeController;
  final HistoryController historyController;

  final Set<String> _triggeredAlarmsToday = {};
  int _lastCheckedMinute = -1;

  bool _hasSentAlarmsOnConnect = false;

  AlarmController({
    required this.homeController,
    required this.historyController,
  }) {
    _startMonitoring();
    homeController.addListener(_onHomeStatusChanged);
    if (kDebugMode) {
      print('AlarmController: Inicializado.');
    }
  }

  final List<Alarm> _alarms = [
    Alarm(
      id: const Uuid().v4(),
      time: const TimeOfDay(hour: 7, minute: 30),
      grams: 50.0,
      repeatDays: [1, 2, 3, 4, 5], // Seg a Sex
      isActive: true,
      isRepeatingWeekly: true,
    ),
  ];

  List<Alarm> get alarms => _alarms;

  void _onHomeStatusChanged() {
    if (kDebugMode) {
      print('AlarmController: _onHomeStatusChanged chamado. Status: ${homeController.status}');
    }
    if (homeController.status == ConnectionStatus.connected) {
      if (!_hasSentAlarmsOnConnect) {
        if (kDebugMode) {
          print('AlarmController: Home Controller conectado, enviando alarmes para o ESP32.');
        }
        _sendAlarmsToEsp32();
        _hasSentAlarmsOnConnect = true;
      }
    } else {
      if (_hasSentAlarmsOnConnect) {
        if (kDebugMode) {
          print('AlarmController: Home Controller desconectado, resetando flag _hasSentAlarmsOnConnect.');
        }
      }
      _hasSentAlarmsOnConnect = false;
    }
  }

  void _startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAlarms();
    });
    if (kDebugMode) {
      print('AlarmController: Monitoramento de alarmes iniciado.');
    }
  }

  void _checkAlarms() {
    final now = DateTime.now();

    if (now.minute == _lastCheckedMinute && (now.hour != 0 || now.minute != 0)) {
      return;
    }
    _lastCheckedMinute = now.minute;

    if (now.hour == 0 && now.minute == 0) {
      _triggeredAlarmsToday.clear();
      if (kDebugMode) {
        print("AlarmController: Lista de alarmes disparados resetada para o novo dia.");
      }
    }

    for (final alarm in _alarms) {
      if (!alarm.isActive) continue;
      if (alarm.repeatDays.isNotEmpty && !alarm.repeatDays.contains(now.weekday)) continue;

      if (alarm.time.hour == now.hour && alarm.time.minute == now.minute) {
        _triggerAlarm(alarm);
      }
    }
  }

  void _triggerAlarm(Alarm alarm) {
    final todayKey = "${alarm.id}_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}";

    if (_triggeredAlarmsToday.contains(todayKey)) {
      if (kDebugMode) {
        // CORREÇÃO AQUI: Formatando TimeOfDay manualmente
        print("AlarmController: Alarme ${alarm.id} (${_formatTimeOfDay(alarm.time)}) já disparado neste minuto do dia. Ignorando.");
      }
      return;
    }

    String timeString = "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}";
    if (kDebugMode) {
      print("AlarmController: ALARME DISPARADO LOCALMENTE: $timeString - ${alarm.grams}g");
    }

    NotificationService().showAlarmNotification(
      title: 'Hora de comer! 🐾',
      body: 'Dispensando ${alarm.grams.toStringAsFixed(0)}g de ração conforme programado.',
    );

    if (homeController.status == ConnectionStatus.connected) {
      homeController.manualFeed(alarm.grams);
      historyController.addEntry(
        type: HistoryType.alarm,
        description: 'Alarme automático executado (${alarm.grams.toStringAsFixed(0)}g).',
        gramsDispensed: alarm.grams,
      );
    } else {
      historyController.addEntry(
        type: HistoryType.error,
        description: 'Alarme falhou: App desconectado do alimentador no alarme das $timeString.',
      );
      NotificationService().showAlarmNotification(
        title: 'Falha no Alarme ⚠️',
        body: 'Não foi possível conectar ao alimentador para o alarme das $timeString.',
      );
    }

    _triggeredAlarmsToday.add(todayKey);

    if (!alarm.isRepeatingWeekly && alarm.repeatDays.isEmpty) {
      if (kDebugMode) {
        print('AlarmController: Alarme único (${alarm.id}) desativado após disparo.');
      }
      toggleAlarmActive(alarm.id);
    }
  }

  void addAlarm({
    required TimeOfDay time,
    required double grams,
    required List<int> days,
    bool isRepeatingWeekly = true,
    bool isActive = true,
  }) {
    final newAlarm = Alarm(
      id: _uuid.v4(),
      time: time,
      grams: grams,
      repeatDays: days,
      isRepeatingWeekly: isRepeatingWeekly,
      isActive: isActive,
    );
    _alarms.add(newAlarm);
    if (kDebugMode) {
      // CORREÇÃO AQUI: Formatando TimeOfDay manualmente
      print('AlarmController: Alarme adicionado: ${newAlarm.id} em ${_formatTimeOfDay(newAlarm.time)}.');
    }
    notifyListeners();
    _sendAlarmsToEsp32();
  }

  void deleteAlarm(String alarmId) {
    _alarms.removeWhere((alarm) => alarm.id == alarmId);
    if (kDebugMode) {
      print('AlarmController: Alarme excluído: $alarmId.');
    }
    notifyListeners();
    _sendAlarmsToEsp32();
  }

  void toggleAlarmActive(String alarmId) {
    final index = _alarms.indexWhere((alarm) => alarm.id == alarmId);
    if (index != -1) {
      _alarms[index].isActive = !_alarms[index].isActive;
      if (kDebugMode) {
        print('AlarmController: Alarme $alarmId ativo: ${_alarms[index].isActive}.');
      }
      notifyListeners();
      _sendAlarmsToEsp32();
    }
  }

  void updateAlarm(Alarm updatedAlarm) {
    final index = _alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      if (kDebugMode) {
        // CORREÇÃO AQUI: Formatando TimeOfDay manualmente
        print('AlarmController: Alarme atualizado: ${updatedAlarm.id} em ${_formatTimeOfDay(updatedAlarm.time)}.');
      }
      notifyListeners();
      _sendAlarmsToEsp32();
    }
  }

  void _sendAlarmsToEsp32() {
    if (kDebugMode) {
      print('AlarmController: _sendAlarmsToEsp32 chamado.');
    }
    if (homeController.status == ConnectionStatus.connected) {
      final List<Map<String, dynamic>> alarmsJsonList =
          _alarms.map((alarm) => alarm.toJson()).toList();
      
      final String alarmsJson = jsonEncode(alarmsJsonList);
      
      homeController.sendAlarmConfiguration(alarmsJson);
    } else {
      if (kDebugMode) {
        print('AlarmController: Não enviando alarmes para ESP32, Home Controller desconectado.');
      }
    }
  }

  // NOVA FUNÇÃO: Para formatar TimeOfDay sem BuildContext
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('AlarmController: dispose() chamado.');
    }
    _timer?.cancel();
    homeController.removeListener(_onHomeStatusChanged);
    super.dispose();
  }
}