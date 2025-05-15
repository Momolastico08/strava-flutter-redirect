import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/exercise_item.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({Key? key}) : super(key: key);

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  List<ExerciseItem> _exercises = [];
  List<ExerciseItem> _selectedExercises = [];
  String _selectedMuscleGroup = 'Tous';

  final List<String> _muscleGroups = [
    'Tous', 'Bras', 'Pecs', 'Dos', 'Jambes', 'Epaules', 'Abdos'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialSelectedExercises = ModalRoute.of(context)?.settings.arguments as List<ExerciseItem>?;
    if (initialSelectedExercises != null) {
      _selectedExercises = List.from(initialSelectedExercises);
    }
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await DatabaseHelper.instance.getExercises();
    setState(() {
      _exercises = exercises;
    });
  }

  void _selectExercise(ExerciseItem exercise) async {
    final updatedExercise = await showDialog<ExerciseItem>(
      context: context,
      builder: (context) => _EditExerciseDialog(exercise: exercise),
    );

    if (updatedExercise != null) {
      setState(() {
        _selectedExercises.removeWhere((e) => e.id == updatedExercise.id);
        _selectedExercises.add(updatedExercise);
      });
    }
  }

  List<ExerciseItem> get _filteredExercises {
    if (_selectedMuscleGroup == 'Tous') return _exercises;
    return _exercises.where((e) => e.muscleGroup == _selectedMuscleGroup).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des exercices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedExercises);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = _selectedMuscleGroup == group;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.deepOrangeAccent : Colors.grey.shade200,
                      foregroundColor: isSelected ? Colors.white : Colors.black87,
                      elevation: isSelected ? 6 : 2,
                      shadowColor: Colors.deepOrangeAccent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMuscleGroup = group;
                      });
                    },
                    child: Text(group),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filteredExercises.isEmpty
                ? const Center(child: Text('Aucun exercice trouvé'))
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isSelected = _selectedExercises.any((e) => e.id == exercise.id);

                return GestureDetector(
                  onTap: () => _selectExercise(exercise),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? Colors.orange.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.asset(
                              'assets/images/${exercise.image}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.fitness_center, size: 50),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${exercise.sets} séries x ${exercise.reps} reps\n${exercise.weight} kg',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EditExerciseDialog extends StatefulWidget {
  final ExerciseItem exercise;

  const _EditExerciseDialog({Key? key, required this.exercise}) : super(key: key);

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(text: widget.exercise.sets.toString());
    _repsController = TextEditingController(text: widget.exercise.reps.toString());
    _weightController = TextEditingController(text: widget.exercise.weight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier ${widget.exercise.name}'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(labelText: 'Séries'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _repsController,
              decoration: const InputDecoration(labelText: 'Répétitions'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Annuler'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Valider'),
          onPressed: () {
            final updatedExercise = ExerciseItem(
              id: widget.exercise.id,
              name: widget.exercise.name,
              sets: int.tryParse(_setsController.text) ?? widget.exercise.sets,
              reps: int.tryParse(_repsController.text) ?? widget.exercise.reps,
              weight: double.tryParse(_weightController.text) ?? widget.exercise.weight,
              muscleGroup: widget.exercise.muscleGroup,
              category: widget.exercise.category,
              image: widget.exercise.image,
            );
            Navigator.pop(context, updatedExercise);
          },
        ),
      ],
    );
  }
}
