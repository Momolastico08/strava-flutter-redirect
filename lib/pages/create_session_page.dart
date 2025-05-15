// lib/pages/create_session_page.dart

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/session_model.dart';
import '../models/exercise_item.dart';
import '../widgets/exercise_card.dart';
import 'add_exercise_to_session.dart';

class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({Key? key}) : super(key: key);

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  String _sessionName = '';
  List<ExerciseItem> selectedExercises = [];

  void _saveSession() async {
    if (_formKey.currentState!.validate() && selectedExercises.isNotEmpty) {
      _formKey.currentState!.save();

      final session = Session(
        name: _sessionName,
        date: DateTime.now(),
        exercises: selectedExercises,
      );

      await DatabaseHelper.instance.insertSession(session);

      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom et ajouter au moins un exercice.')),
      );
    }
  }

  void _removeExercise(int index) {
    setState(() {
      selectedExercises.removeAt(index);
    });
  }

  Future<void> _addExercise() async {
    final exercise = await Navigator.push<ExerciseItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddExerciseToSessionPage()),
    );
    if (exercise != null) {
      setState(() {
        selectedExercises.add(exercise);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle séance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom de la séance'),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un nom' : null,
                onSaved: (value) => _sessionName = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un exercice'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedExercises.isEmpty
                    ? const Center(child: Text('Aucun exercice ajouté'))
                    : ListView.builder(
                  itemCount: selectedExercises.length,
                  itemBuilder: (context, index) {
                    return ExerciseCard(
                      exercise: selectedExercises[index],
                      onDelete: () => _removeExercise(index),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _saveSession,
                child: const Text('Créer la séance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
