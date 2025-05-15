// lib/pages/add_exercise_to_session.dart

import 'package:flutter/material.dart';
import '../models/exercise_item.dart';
import 'category_exercises_page.dart';

class AddExerciseToSessionPage extends StatefulWidget {
  const AddExerciseToSessionPage({Key? key}) : super(key: key);

  @override
  State<AddExerciseToSessionPage> createState() => _AddExerciseToSessionPageState();
}

class _AddExerciseToSessionPageState extends State<AddExerciseToSessionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un exercice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryTile('CrossFit', Icons.flash_on, Colors.redAccent),
          _buildCategoryTile('Trail', Icons.terrain, Colors.green),
          _buildCategoryTile('Salle', Icons.fitness_center, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String label, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          final selectedExercise = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryExercisesPage(category: label), // ✅ ici la bonne page
            ),
          );

          if (selectedExercise != null && selectedExercise is ExerciseItem) {
            Navigator.pop(context, selectedExercise);
          }
        },
      ),
    );
  }
}
