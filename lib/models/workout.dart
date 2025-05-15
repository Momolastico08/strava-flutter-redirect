class Workout {
  final int? id;
  final int exerciseId;
  final int sets;
  final int reps;
  final double weight;
  final DateTime date;

  Workout({
    this.id,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      exerciseId: map['exerciseId'],
      sets: map['sets'],
      reps: map['reps'],
      weight: (map['weight'] as num).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }
}
