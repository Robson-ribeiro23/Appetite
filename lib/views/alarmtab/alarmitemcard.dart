// lib/views/alarms_tab/alarm_item_card.dart
import 'package:flutter/material.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/core/constants/appcolors.dart';

class AlarmItemCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const AlarmItemCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'Não repete';
    
    final dayMap = {1: 'SEG', 2: 'TER', 3: 'QUA', 4: 'QUI', 5: 'SEX', 6: 'SAB', 7: 'DOM'};
    
    return days.map((day) => dayMap[day]).whereType<String>().join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: alarm.isActive ? AppColors.darkBackground : Colors.grey.shade800,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hora do Alarme
            Text(
              alarm.time.format(context),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: alarm.isActive ? theme.primaryColor : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantidade em Gramas
                  Text(
                    '${alarm.grams.toStringAsFixed(1)} gramas',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: alarm.isActive ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dias da Semana
                  Text(
                    _formatDays(alarm.repeatDays),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: alarm.isActive ? Colors.white70 : Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // Switch para Ativar/Desativar
            Switch(
              value: alarm.isActive,
              onChanged: (val) => onToggle(),
              activeTrackColor: theme.colorScheme.secondary,
            ),
            
            // Botão de Opções (Editar e Excluir)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Excluir'),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}