// lib/pages/training_categories_page.dart

import 'package:flutter/material.dart';
import 'category_exercises_page.dart';
import '../models/exercise_item.dart';

class TrainingCategoriesPage extends StatelessWidget {
  final String category;

  const TrainingCategoriesPage({Key? key, required this.category}) : super(key: key);


  void _openCategory(BuildContext context, String category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CategoryExercisesPage(category: category),
      ),
    );

    if (result != null && result is ExerciseItem) {
      Navigator.pop(context, result); // Retourne l'exercice choisi à la page précédente
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Choisir une catégorie',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildCategoryCard(context, 'Salle', Icons.fitness_center, Colors.blue),
        _buildCategoryCard(context, 'CrossFit', Icons.flash_on, Colors.redAccent),
        _buildCategoryCard(context, 'Trail', Icons.terrain, Colors.green),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String label, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openCategory(context, label),
      ),
    );
  }
}
