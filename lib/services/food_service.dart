// lib/models/food.dart

class Food {
  final String name;
  final String image;
  final int caloriesPer100g;
  final int proteinsPer100g;

  Food({
    required this.name,
    required this.image,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
  });

  /// Crée un objet Food à partir d'un JSON (ex: depuis assets/data/foods.json)
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      caloriesPer100g: (json['kcal100'] as num?)?.toInt() ?? 0,
      proteinsPer100g: (json['prot100'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convertit l'objet Food en JSON (ex: pour sauvegarde en base)
  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'caloriesPer100g': caloriesPer100g,
    'proteinsPer100g': proteinsPer100g,
  };
}
