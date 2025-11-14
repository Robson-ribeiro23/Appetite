// lib/views/alarms_tab/alarm_item_card.dart
import 'package:flutter/material.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/core/constants/app_colors.dart'; // Corrigido para app_colors.dart

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
      // CORREÇÃO: Usar background do tema para cards
      color: alarm.isActive 
        ? theme.cardColor // Pode ser um pouco mais escuro ou o fundo primário
        : theme.hoverColor, // Ou outra cor que indique desativado, mas respeite o tema
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              alarm.time.format(context),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: alarm.isActive ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withOpacity(0.5), // CORREÇÃO
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alarm.grams.toStringAsFixed(1)} gramas',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: alarm.isActive ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyLarge?.color?.withOpacity(0.5), // CORREÇÃO
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDays(alarm.repeatDays),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: alarm.isActive ? theme.textTheme.bodyMedium?.color?.withOpacity(0.7) : theme.textTheme.bodySmall?.color, // CORREÇÃO
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            Switch(
              value: alarm.isActive,
              onChanged: (val) => onToggle(),
              activeTrackColor: theme.colorScheme.secondary,
            ),
            
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                // CORREÇÃO: Definir TextStyle para os itens do menu
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Editar', style: theme.textTheme.bodyMedium),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Excluir', style: theme.textTheme.bodyMedium),
                ),
              ],
              icon: Icon(Icons.more_vert, color: theme.iconTheme.color), // CORREÇÃO
            ),
          ],
        ),
      ),
    );
  }
}