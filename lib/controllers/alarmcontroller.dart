import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/controllers/homecontroller.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:appetite/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class AlarmController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  Timer? _timer;

  // Controladores externos que precisaremos acessar
  final HomeController homeController;
  final HistoryController historyController;

  // Para evitar que o mesmo alarme dispare várias vezes no mesmo minuto
  final Set<String> _triggeredAlarmsToday = {};
  int _lastCheckedMinute = -1;

  AlarmController({
    required this.homeController,
    required this.historyController,
  }) {
    // Inicia o monitoramento assim que o Controller é criado
    _startMonitoring();
  }

  // Lista privada de alarmes
  final List<Alarm> _alarms = [
    Alarm(
      id: const Uuid().v4(),
      time: const TimeOfDay(hour: 7, minute: 30),
      grams: 50.0,
      repeatDays: [1, 2, 3, 4, 5], // Seg a Sex
      isActive: true,
    ),
  ];

  List<Alarm> get alarms => _alarms;

  // --- MONITORAMENTO DE TEMPO ---
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
      if (!alarm.repeatDays.contains(now.weekday)) continue;

      if (alarm.time.hour == now.hour && alarm.time.minute == now.minute) {
        _triggerAlarm(alarm);
      }
    }
  }

  void _triggerAlarm(Alarm alarm) {
    final todayKey = "${alarm.id}_${DateTime.now().day}";

    if (_triggeredAlarmsToday.contains(todayKey)) return;

    // --- CORREÇÃO AQUI ---
    // Usamos hour e minute diretamente em vez de .format(context)
    String timeString =
        "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}";
    print("ALARME DISPARADO: $timeString - ${alarm.grams}g");
    // ---------------------

    NotificationService().showAlarmNotification(
      title: 'Hora de comer! 🐾',
      body:
          'Dispensando ${alarm.grams.toStringAsFixed(0)}g de ração conforme programado.',
    );

    if (homeController.status == ConnectionStatus.connected) {
      homeController.manualFeed(alarm.grams);

      historyController.addEntry(
        type: HistoryType.alarm,
        description: 'Alarme automático executado.',
        gramsDispensed: alarm.grams,
      );
    } else {
      historyController.addEntry(
        type: HistoryType.error,
        description: 'Alarme falhou: App desconectado do alimentador.',
      );
      NotificationService().showAlarmNotification(
        title: 'Falha no Alarme ⚠️',
        body:
            'Não foi possível conectar ao alimentador para o alarme das $timeString.',
      );
    }

    _triggeredAlarmsToday.add(todayKey);

    if (!alarm.isRepeatingWeekly && alarm.repeatDays.isEmpty) {
      toggleAlarmActive(alarm.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Métodos CRUD ---
  void addAlarm(
      {required TimeOfDay time,
      required double grams,
      required List<int> days}) {
    final newAlarm =
        Alarm(id: _uuid.v4(), time: time, grams: grams, repeatDays: days);
    _alarms.add(newAlarm);
    notifyListeners();
  }

  void deleteAlarm(String alarmId) {
    _alarms.removeWhere((alarm) => alarm.id == alarmId);
    notifyListeners();
  }

  void toggleAlarmActive(String alarmId) {
    final index = _alarms.indexWhere((alarm) => alarm.id == alarmId);
    if (index != -1) {
      _alarms[index].isActive = !_alarms[index].isActive;
      notifyListeners();
    }
  }

  void updateAlarm(Alarm updatedAlarm) {
    final index = _alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      notifyListeners();
    }
  }
}