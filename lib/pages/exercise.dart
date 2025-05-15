// lib/models/exercise.dart

class Exercise {
  final int? id;
  final String name;
  final String category;
  final String image;

  Exercise({
    this.id,
    required this.name,
    required this.category,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'image': image,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      image: map['image'],
    );
  }
}
