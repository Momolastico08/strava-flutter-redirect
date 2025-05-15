class ExerciseItem {
  final int? id;
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final String muscleGroup; // Sous-catégorie (ex: Jambes, Dos)
  final String category;    // Catégorie principale (ex: Salle, CrossFit)
  final String image;

  ExerciseItem({
    this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.muscleGroup,
    required this.category,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'muscleGroup': muscleGroup,
      'category': category,
      'image': image,
    };
  }

  factory ExerciseItem.fromMap(Map<String, dynamic> map) {
    return ExerciseItem(
      id: map['id'],
      name: map['name'],
      sets: map['sets'],
      reps: map['reps'],
      weight: (map['weight'] as num).toDouble(),
      muscleGroup: map['muscleGroup'],
      category: map['category'],
      image: map['image'],
    );
  }

  factory ExerciseItem.withId({required int id}) {
    return ExerciseItem(
      id: id,
      name: '',
      sets: 0,
      reps: 0,
      weight: 0.0,
      muscleGroup: 'Autre',
      category: 'Autre',
      image: 'default.png',
    );
  }

  factory ExerciseItem.empty() {
    return ExerciseItem(
      id: 0,
      name: 'Exercice inconnu',
      sets: 0,
      reps: 0,
      weight: 0.0,
      muscleGroup: 'Autre',
      category: 'Autre',
      image: 'default.png',
    );
  }
}
