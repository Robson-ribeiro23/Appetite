// lib/controllers/alarm_controller.dart
import 'package:flutter/material.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:uuid/uuid.dart'; // Usaremos um pacote para gerar IDs

class AlarmController extends ChangeNotifier {
  // Lista privada de alarmes
  final List<Alarm> _alarms = [
    // Exemplo de Alarme (Sexta às 7:30, 50g, Ativo)
    Alarm(
      id: const Uuid().v4(),
      time: const TimeOfDay(hour: 7, minute: 30),
      grams: 50.0,
      repeatDays: [5], // 5 = Sexta-feira
    ),
  ];

  // Getter para que a UI possa ler a lista
  List<Alarm> get alarms => _alarms;
  
  // O construtor para inicializar o gerador de UUID
  final Uuid _uuid = const Uuid();

  // --- Métodos CRUD ---

  void addAlarm({
    required TimeOfDay time,
    required double grams,
    required List<int> days,
  }) {
    final newAlarm = Alarm(
      id: _uuid.v4(),
      time: time,
      grams: grams,
      repeatDays: days,
    );
    _alarms.add(newAlarm);
    // Notifica a UI (a lista) que o estado mudou e precisa ser reconstruído
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