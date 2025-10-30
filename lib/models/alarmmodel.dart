// lib/models/alarm_model.dart
import 'package:flutter/material.dart';

class Alarm {
  // Um ID único para facilitar a edição e exclusão (importante para listas)
  final String id;
  
  // O horário que o alarme irá tocar
  TimeOfDay time;
  
  // A quantidade em gramas a ser dispensada
  double grams;
  
  // Lista de dias da semana (1=Seg, 2=Ter, ..., 7=Dom)
  List<int> repeatDays;
  
  // Indica se o alarme está ativo ou desativado
  bool isActive;
  
  // Indica se o alarme deve se repetir semanalmente (além dos dias escolhidos)
  bool isRepeatingWeekly;

  Alarm({
    required this.id,
    required this.time,
    required this.grams,
    required this.repeatDays,
    this.isActive = true, // Por padrão, o alarme é criado ativo
    this.isRepeatingWeekly = true,
  });

  // Método para criar uma cópia do objeto (útil para edição)
  Alarm copyWith({
    TimeOfDay? time,
    double? grams,
    List<int>? repeatDays,
    bool? isActive,
    bool? isRepeatingWeekly,
  }) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      grams: grams ?? this.grams,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      isRepeatingWeekly: isRepeatingWeekly ?? this.isRepeatingWeekly,
    );
  }
}