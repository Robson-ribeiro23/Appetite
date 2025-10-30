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
    return Consumer<AlarmController>(
      builder: (context, controller, child) {
        if (controller.alarms.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum alarme configurado. Toque no "+" para adicionar.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Stack(
          children: [
            // A Lista Scrollável de Alarmes
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

            // O Botão Flutuante Centralizado na parte Inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0), 
                child: FloatingActionButton(
                  onPressed: () => _showAddEditAlarm(context, controller), 
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 30.0, color: Colors.black),
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