// lib/controllers/historycontroller.dart
import 'package:flutter/material.dart';
import 'package:appetite/models/historyentrymodel.dart';
import 'package:uuid/uuid.dart';

class HistoryController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  // --- ALTERAÇÃO: Lista inicia vazia, sem placeholders ---
  final List<HistoryEntry> _history = []; 

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
  
  // Opcional: Método para limpar histórico manualmente se precisar no futuro
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}