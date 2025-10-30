// lib/models/history_entry_model.dart


// Tipos de eventos possíveis no histórico
enum HistoryType { 
  alarm, // Evento gerado por um alarme automático
  manual, // Evento gerado por acionamento manual na HomeTab
  error // Evento de erro (ex: falha de conexão ou dispensa)
}

class HistoryEntry {
  final String id;
  final DateTime timestamp; // Quando o evento ocorreu
  final HistoryType type;   // O tipo de evento
  final String description; // Detalhe do evento (ex: "Alarme das 7:00 concluído")
  final double? gramsDispensed; // Quantidade dispensada (opcional)

  HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    this.gramsDispensed,
  });
}