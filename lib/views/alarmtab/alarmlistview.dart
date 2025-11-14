// lib/views/alarms_tab/alarm_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/models/alarmmodel.dart';
import 'package:appetite/views/alarmtab/alarmitemcard.dart';
import 'package:appetite/views/alarmtab/addalarmdialog.dart';

class AlarmListView extends StatelessWidget {
  const AlarmListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Obtém o tema aqui

    return Consumer<AlarmController>(
      builder: (context, controller, child) {
        if (controller.alarms.isEmpty) {
          return Center(
            child: Text(
              'Nenhum alarme configurado. Toque no "+" para adicionar.',
              // CORREÇÃO: Usar cor de texto secundária do tema
              style: theme.textTheme.bodyMedium, 
              textAlign: TextAlign.center,
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              itemCount: controller.alarms.length,
              itemBuilder: (context, index) {
                final alarm = controller.alarms[index];
                return AlarmItemCard(
                  alarm: alarm,
                  onToggle: () => controller.toggleAlarmActive(alarm.id),
                  onDelete: () => controller.deleteAlarm(alarm.id),
                  onEdit: () => _showAddEditAlarm(context, controller, alarm),
                );
              },
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0), 
                child: FloatingActionButton(
                  onPressed: () => _showAddEditAlarm(context, controller), 
                  backgroundColor: theme.primaryColor,
                  shape: const CircleBorder(),
                  foregroundColor: theme.colorScheme.onPrimary, // CORREÇÃO: Cor do ícone no FAB
                  child: const Icon(Icons.add, size: 30.0), // Removido 'color: Colors.black'
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditAlarm(BuildContext context, AlarmController controller, [Alarm? alarmToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (context) {
        return AddAlarmDialog(alarmToEdit: alarmToEdit);
      },
    );
  }
}