import 'dart:async';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:appetite/services/notification_service.dart';
import 'package:uuid/uuid.dart';

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
  }

  final List<Alarm> _alarms = [
    Alarm(
      id: const Uuid().v4(),
      time: const TimeOfDay(hour: 7, minute: 30),
      grams: 50.0,
      repeatDays: [1, 2, 3, 4, 5], 
      isActive: true,
    ),
  ];
  
  List<Alarm> get alarms => _alarms;

  void _onHomeStatusChanged() {
    if (homeController.status == ConnectionStatus.connected) {
      if (!_hasSentAlarmsOnConnect) {
        if (kDebugMode) print('DIAGNOSTICO: Conectado detectado. Enviando lista inicial...');
        _sendAlarmsToEsp32();
        _hasSentAlarmsOnConnect = true;
      }
    } else {
      _hasSentAlarmsOnConnect = false;
    }
  }

  void _sendAlarmsToEsp32() {
    // DIAGNÓSTICO DE ENVIO
    if (kDebugMode) print('DIAGNOSTICO: Tentando enviar alarmes...');
    
    if (homeController.status != ConnectionStatus.connected) {
      if (kDebugMode) print('DIAGNOSTICO: FALHA. Status atual: ${homeController.status}. Esperado: connected');
      return;
    }

    try {
      final List<Map<String, dynamic>> alarmsJsonList =
          _alarms.map((alarm) => alarm.toJson()).toList();
      
      final String alarmsJson = jsonEncode(alarmsJsonList);
      
      homeController.sendAlarmConfiguration(alarmsJson);
      
      if (kDebugMode) print('DIAGNOSTICO: SUCESSO. Lista JSON enviada para o HomeController.');
    } catch (e) {
      if (kDebugMode) print('DIAGNOSTICO: ERRO ao criar JSON: $e');
    }
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    if (now.minute == _lastCheckedMinute) return;
    _lastCheckedMinute = now.minute;

    if (now.hour == 0 && now.minute == 0) {
      _triggeredAlarmsToday.clear();
    }

    for (final alarm in _alarms) {
      if (!alarm.isActive) continue;
      // (Lógica de dias simplificada para teste)
      if (alarm.time.hour == now.hour && alarm.time.minute == now.minute) {
        _triggerAlarm(alarm);
      }
    }
  }

  void _triggerAlarm(Alarm alarm) {
    final todayKey = "${alarm.id}_${DateTime.now().day}";
    if (_triggeredAlarmsToday.contains(todayKey)) return;

    String timeString = "${alarm.time.hour}:${alarm.time.minute}";
    
    NotificationService().showAlarmNotification(
      title: 'Hora de comer! 🐾',
      body: 'Horário programado: $timeString.',
    );

    historyController.addEntry(
      type: HistoryType.alarm,
      description: 'Alarme do app disparado ($timeString).',
      gramsDispensed: alarm.grams,
    );

    _triggeredAlarmsToday.add(todayKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    homeController.removeListener(_onHomeStatusChanged);
    super.dispose();
  }

  // --- CRUD COM DIAGNÓSTICO ---

  void addAlarm({required TimeOfDay time, required double grams, required List<int> days}) {
    if (kDebugMode) print('DIAGNOSTICO: Adicionando alarme...');
    final newAlarm = Alarm(id: _uuid.v4(), time: time, grams: grams, repeatDays: days);
    _alarms.add(newAlarm);
    notifyListeners();
    _sendAlarmsToEsp32(); 
  }

  void deleteAlarm(String alarmId) {
    if (kDebugMode) print('DIAGNOSTICO: Excluindo alarme...');
    _alarms.removeWhere((alarm) => alarm.id == alarmId);
    notifyListeners();
    _sendAlarmsToEsp32();
  }

  void toggleAlarmActive(String alarmId) {
    final index = _alarms.indexWhere((alarm) => alarm.id == alarmId);
    if (index != -1) {
      _alarms[index].isActive = !_alarms[index].isActive;
      notifyListeners();
      _sendAlarmsToEsp32();
    }
  }

  void updateAlarm(Alarm updatedAlarm) {
    if (kDebugMode) print('DIAGNOSTICO: Atualizando alarme...');
    final index = _alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      notifyListeners();
      _sendAlarmsToEsp32();
    }
  }
}