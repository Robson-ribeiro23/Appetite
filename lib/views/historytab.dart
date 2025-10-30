// lib/views/history_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/historycontroller.dart';
import 'package:appetite/models/historyentrymodel.dart';


class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (context, controller, child) {
        if (controller.history.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum histórico de atividade registrado.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: controller.history.length,
          itemBuilder: (context, index) {
            final entry = controller.history[index];
            return _HistoryItemCard(entry: entry);
          },
        );
      },
    );
  }
}

// Widget privado para exibir um item do histórico
class _HistoryItemCard extends StatelessWidget {
  final HistoryEntry entry;
  
  const _HistoryItemCard({required this.entry});

  Map<String, dynamic> _getStyle(HistoryType type, ThemeData theme) {
    switch (type) {
      case HistoryType.alarm:
        return {'icon': Icons.alarm_on, 'color': theme.primaryColor};
      case HistoryType.manual:
        return {'icon': Icons.touch_app, 'color': theme.colorScheme.secondary};
      case HistoryType.error:
        return {'icon': Icons.warning_amber, 'color': Colors.red.shade400};
      //default:
        //return {'icon': Icons.info_outline, 'color': Colors.grey};
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _getStyle(entry.type, theme);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (style['color'] as Color).withAlpha((255 * 0.2).toInt()),
        child: Icon(style['icon'], color: style['color']),
      ),
      title: Text(
        entry.description,
        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
      subtitle: Text(
        _formatDateTime(entry.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
      ),
      trailing: entry.gramsDispensed != null
          ? Text(
              '${entry.gramsDispensed!.toStringAsFixed(1)}g',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}