import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/exercise_item.dart';
import '../models/workout.dart'; // ← nouveau : importe ton modèle Workout ici

class AddWorkoutPage extends StatefulWidget {
  final ExerciseItem exercise;

  const AddWorkoutPage({Key? key, required this.exercise}) : super(key: key);

  @override
  _AddWorkoutPageState createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  int _sets = 0;
  int _reps = 0;
  double _weight = 0.0;

  Future<void> _saveWorkout() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final workout = Workout(
        exerciseId: widget.exercise.id!, // <-- on stocke juste l'ID de l'exercice
        sets: _sets,
        reps: _reps,
        weight: _weight,
        date: DateTime.now(),
      );

      await DatabaseHelper.instance.insertWorkout(workout);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un exercice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Exercice : ${widget.exercise.name}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Séries'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Entrez un nombre de séries' : null,
                onSaved: (value) => _sets = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Répétitions'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Entrez un nombre de répétitions' : null,
                onSaved: (value) => _reps = int.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Poids (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || value.isEmpty ? 'Entrez un poids' : null,
                onSaved: (value) => _weight = double.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkout,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
