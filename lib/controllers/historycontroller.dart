// lib/controllers/history_controller.dart
import 'package:flutter/material.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:uuid/uuid.dart'; // Para gerar IDs únicos

class HistoryController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  
  // Lista privada de histórico (com alguns dados simulados para começar)
  final List<HistoryEntry> _history = [
    HistoryEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      type: HistoryType.alarm,
      description: 'Alarme das 08:00h concluído.',
      gramsDispensed: 50.0,
    ),
    HistoryEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: HistoryType.manual,
      description: 'Acionamento manual de 30g.',
      gramsDispensed: 30.0,
    ),
    HistoryEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: HistoryType.error,
      description: 'Falha na conexão com ESP32 durante acionamento.',
    ),
  ];

  // Getter que retorna a lista ordenada pela data mais recente
  List<HistoryEntry> get history {
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _history;
  }

  // Método para adicionar uma nova entrada de histórico
  void addEntry({
    required HistoryType type,
    required String description,
    double? gramsDispensed,
  }) {
    final newEntry = HistoryEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: type,
      description: description,
      gramsDispensed: gramsDispensed,
    );
    _history.add(newEntry);
    notifyListeners();
  }
}