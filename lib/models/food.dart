class Food {
  final String name;
  final String image;
  final int caloriesPer100g;
  final int proteinsPer100g;
  final int carbsPer100g;
  final int fatsPer100g;
  final String? category; // 🆕 ajouté

  Food({
    required this.name,
    required this.image,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    this.category, // 🆕 ajouté
  });

  factory Food.fromJson(Map<String, dynamic> m) {
    return Food(
      name: m['name'] as String? ?? '',
      image: m['image'] as String? ?? '',
      caloriesPer100g: (m['kcal100'] as num?)?.toInt() ?? 0,
      proteinsPer100g: (m['prot100'] as num?)?.toInt() ?? 0,
      carbsPer100g: (m['carb100'] as num?)?.toInt() ?? 0,
      fatsPer100g: (m['fat100'] as num?)?.toInt() ?? 0,
      category: m['category'] as String?, // 🆕 ajouté
    );
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['name'],
      image: map['image'],
      caloriesPer100g: map['caloriesPer100g'],
      proteinsPer100g: map['proteinsPer100g'],
      carbsPer100g: map['carbsPer100g'] ?? 0,
      fatsPer100g: map['fatsPer100g'] ?? 0,
      category: map['category'], // 🆕 ajouté
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'caloriesPer100g': caloriesPer100g,
    'proteinsPer100g': proteinsPer100g,
    'carbsPer100g': carbsPer100g,
    'fatsPer100g': fatsPer100g,
    'category': category, // 🆕 ajouté
  };

  Map<String, dynamic> toMap() => toJson();
}
