// lib/pages/session_detail_page.dart

import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/exercise_item.dart';
import '../services/database_helper.dart';
import 'exercise_list_page.dart';

class SessionDetailPage extends StatefulWidget {
  final Session session;

  const SessionDetailPage({Key? key, required this.session}) : super(key: key);

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  late TextEditingController _nameController;
  late List<ExerciseItem> _exercises;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _exercises = List.from(widget.session.exercises);
  }

  Future<void> _saveSession() async {
    final updatedSession = Session(
      id: widget.session.id,
      name: _nameController.text.trim(),
      date: widget.session.date,
      exercises: _exercises,
    );
    await DatabaseHelper.instance.updateSession(updatedSession);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _navigateToAddExercises() async {
    final result = await Navigator.push<List<ExerciseItem>>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseListPage()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _exercises.addAll(result);
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _editExercise(BuildContext context, int index) async {
    final exercise = _exercises[index];
    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.reps.toString());
    final weightController = TextEditingController(text: exercise.weight.toStringAsFixed(1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Séries'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Répétitions'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exercises[index] = ExerciseItem(
                  id: exercise.id,
                  name: exercise.name,
                  sets: int.tryParse(setsController.text) ?? exercise.sets,
                  reps: int.tryParse(repsController.text) ?? exercise.reps,
                  weight: double.tryParse(weightController.text) ?? exercise.weight,
                  muscleGroup: exercise.muscleGroup,
                  category: exercise.category,
                  image: exercise.image,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalVolume = _exercises.fold<double>(
      0,
          (sum, e) => sum + (e.sets * e.reps * e.weight),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la séance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSession,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de la séance'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToAddExercises,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter des exercices'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(child: Text('Aucun exercice'))
                  : ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        exercise.name.isNotEmpty ? exercise.name : 'Exercice ${exercise.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${exercise.sets} séries x ${exercise.reps} reps - ${exercise.weight} kg\nGroupe: ${exercise.muscleGroup}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/${exercise.image}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.fitness_center, size: 50);
                          },
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editExercise(context, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeExercise(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Volume total : ${totalVolume.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}