// lib/models/alarmmodel.dart

import 'package:flutter/material.dart';

class Alarm {
  final String id;
  TimeOfDay time;
  double grams;
  List<int> repeatDays; // 1 = Seg, 7 = Dom
  bool isActive;
  bool isRepeatingWeekly; 

  Alarm({
    required this.id,
    required this.time,
    required this.grams,
    this.repeatDays = const [],
    this.isActive = true,
    this.isRepeatingWeekly = true, 
  });

  // --- NOVO: Método copyWith para facilitar a atualização ---
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

  // Método para converter o objeto Alarm em um Map para JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': time.hour,
        'minute': time.minute,
        'grams': grams,
        'repeatDays': repeatDays,
        'isActive': isActive,
        'isRepeatingWeekly': isRepeatingWeekly,
      };

  // Método de fábrica para criar um objeto Alarm a partir de um Map JSON
  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String,
        time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
        grams: (json['grams'] as num).toDouble(),
        repeatDays: (json['repeatDays'] as List<dynamic>).map((e) => e as int).toList(),
        isActive: json['isActive'] as bool,
        isRepeatingWeekly: json['isRepeatingWeekly'] as bool,
      );
}