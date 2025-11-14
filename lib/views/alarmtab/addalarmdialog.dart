// lib/views/alarms_tab/add_alarm_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appetite/controllers/alarmcontroller.dart';
import 'package:appetite/models/alarmmodel.dart';
// import 'package:appetite/core/constants/app_colors.dart'; // Não é mais necessário para cores de fundo hardcoded

class AddAlarmDialog extends StatefulWidget {
  final Alarm? alarmToEdit; 

  const AddAlarmDialog({super.key, this.alarmToEdit});

  @override
  State<AddAlarmDialog> createState() => _AddAlarmDialogState();
}

class _AddAlarmDialogState extends State<AddAlarmDialog> {
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late bool _isRepeatingWeekly;
  late TextEditingController _gramsController;
  late String _title;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.alarmToEdit != null;
    final alarm = widget.alarmToEdit;

    _title = isEditing ? 'Editar Alarme' : 'Adicionar Novo Alarme';
    
    _selectedTime = alarm?.time ?? TimeOfDay.now();
    _selectedDays = alarm?.repeatDays ?? [DateTime.now().weekday]; 
    _isRepeatingWeekly = alarm?.isRepeatingWeekly ?? true;
    _gramsController = TextEditingController(text: alarm?.grams.toStringAsFixed(0) ?? '50');
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        // CORREÇÃO: Usar o tema atual, não ThemeData.dark() hardcoded
        // E ajustar o ColorScheme para respeitar o tema primário e secundário
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith( // Copia o tema atual e sobrescreve
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: theme.colorScheme.onPrimary, // Cor do texto/ícones no primário
              surface: theme.cardColor, // Fundo do seletor
              onSurface: theme.textTheme.bodyLarge?.color, // Cor do texto no seletor
            ),
            textButtonTheme: TextButtonThemeData( // Para botões de OK/CANCELAR
              style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
            ),
            // Adicione outras customizações para TimePicker se precisar
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
  }
  
  void _saveAlarm() {
    final controller = Provider.of<AlarmController>(context, listen: false);
    
    if (_gramsController.text.isEmpty || double.tryParse(_gramsController.text) == null) {
       return; 
    }
    
    final double grams = double.parse(_gramsController.text);
    
    if (widget.alarmToEdit == null) {
      controller.addAlarm(
        time: _selectedTime,
        grams: grams,
        days: _selectedDays,
      );
    } else {
      final updatedAlarm = widget.alarmToEdit!.copyWith(
        time: _selectedTime,
        grams: grams,
        repeatDays: _selectedDays,
        isRepeatingWeekly: _isRepeatingWeekly,
      );
      controller.updateAlarm(updatedAlarm);
    }

    Navigator.pop(context); 
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.alarmToEdit != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9, 
      padding: const EdgeInsets.all(24.0),
      // CORREÇÃO: Usar a cor de fundo do tema para o Container
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Ou theme.cardColor
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _title,
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor),
            textAlign: TextAlign.center,
          ),
          // CORREÇÃO: Cor da Divider baseada no tema
          Divider(color: theme.dividerColor), 
          
          ListTile(
            leading: Icon(Icons.access_time, color: theme.primaryColor),
            title: Text(
              'Hora: ${_selectedTime.format(context)}',
              style: theme.textTheme.titleLarge,
            ),
            trailing: Icon(Icons.edit, color: theme.iconTheme.color), // CORREÇÃO
            onTap: _selectTime,
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _gramsController,
            keyboardType: TextInputType.number,
            style: theme.textTheme.titleLarge, // CORREÇÃO
            decoration: InputDecoration(
              labelText: 'Quantidade em Gramas',
              labelStyle: TextStyle(color: theme.primaryColor),
              suffixText: 'g',
              suffixStyle: theme.textTheme.titleMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor), // CORREÇÃO
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Dias da Semana:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = index + 1; // 1 = Segunda, 7 = Domingo
              final dayName = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][index];
              final isSelected = _selectedDays.contains(day);

              return GestureDetector(
                onTap: () => _toggleDay(day),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.primaryColor : theme.disabledColor, // CORREÇÃO: Cor do botão de dia
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color, // CORREÇÃO: Cor do texto do dia
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Repetir Semanalmente:', style: theme.textTheme.titleMedium),
              Switch(
                value: _isRepeatingWeekly,
                onChanged: (val) {
                  setState(() {
                    _isRepeatingWeekly = val;
                  });
                },
                activeTrackColor: theme.colorScheme.secondary,
              ),
            ],
          ),
          
          const Spacer(),
          
          ElevatedButton(
            onPressed: _saveAlarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isEditing ? 'Atualizar Alarme' : 'Salvar Alarme',
              style: theme.textTheme.labelLarge?.copyWith(fontSize: 18, color: theme.colorScheme.onPrimary), // CORREÇÃO
            ),
          ),
          const SizedBox(height: 8),
          
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))), // CORREÇÃO
          ),
        ],
      ),
    );
  }
}