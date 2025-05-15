// lib/models/meal_model.dart

import 'dart:convert';
import 'food.dart';

class Meal {
  final int? id;
  final String name;
  final DateTime date;
  final List<MealItem> items;

  Meal({
    this.id,
    required this.name,
    required this.date,
    required this.items,
  });

  // --- Ajout des getters pratiques ---
  double get totalCalories {
    return items.fold(0, (sum, item) => sum + (item.food.caloriesPer100g * item.quantity) / 100);
  }

  double get totalProteins {
    return items.fold(0, (sum, item) => sum + (item.food.proteinsPer100g * item.quantity) / 100);
  }

  // --- Serialization pour la base de données ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'items': jsonEncode(items.map((e) => e.toMap()).toList()),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      items: (jsonDecode(map['items']) as List)
          .map((e) => MealItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MealItem {
  final Food food;
  final int quantity; // quantité en grammes

  MealItem({
    required this.food,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'food': food.toMap(),
      'quantity': quantity,
    };
  }

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      food: Food.fromMap(map['food'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
    );
  }
}