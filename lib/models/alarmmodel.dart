// lib/models/alarmmodel.dart
import 'package:flutter/material.dart';

class Alarm {
  final String id;
  TimeOfDay time;
  double grams;
  List<int> repeatDays; // 1=Seg, 2=Ter, ..., 7=Dom
  bool isActive;
  bool isRepeatingWeekly;

  Alarm({
    required this.id,
    required this.time,
    required this.grams,
    required this.repeatDays,
    this.isActive = true,
    this.isRepeatingWeekly = true,
  });

  // Método para criar uma cópia do objeto (útil para edição)
  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    double? grams,
    List<int>? repeatDays,
    bool? isActive,
    bool? isRepeatingWeekly,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      grams: grams ?? this.grams,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      isRepeatingWeekly: isRepeatingWeekly ?? this.isRepeatingWeekly,
    );
  }

  // --- NOVO MÉTODO: Converte para JSON para enviar ao ESP32 ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'grams': grams,
      'repeatDays': repeatDays,
      'isActive': isActive,
      'isRepeatingWeekly': isRepeatingWeekly,
    };
  }
}