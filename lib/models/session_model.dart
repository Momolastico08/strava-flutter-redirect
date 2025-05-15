// lib/models/session_model.dart
import 'dart:convert';
import 'exercise_item.dart';

class Session {
  final int? id;
  final String name;
  final DateTime date;
  final List<ExerciseItem> exercises;

  Session({
    this.id,
    required this.name,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      exercises: (jsonDecode(map['exercises'] as String) as List)
          .map((e) => ExerciseItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
