import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/session_model.dart';
import '../models/exercise_item.dart';
import 'add_exercise_to_session.dart';
import 'strava_import_page.dart';

class CreateTrainingSessionPage extends StatefulWidget {
  const CreateTrainingSessionPage({Key? key}) : super(key: key);

  @override
  State<CreateTrainingSessionPage> createState() => _CreateTrainingSessionPageState();
}

class _CreateTrainingSessionPageState extends State<CreateTrainingSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  List<ExerciseItem> selectedExercises = [];

  Future<void> _saveSession() async {
    if (_formKey.currentState!.validate() && selectedExercises.isNotEmpty) {
      final session = Session(
        name: _nameController.text.trim(),
        date: DateTime.now(),
        exercises: selectedExercises,
      );

      await DatabaseHelper.instance.insertSession(session);

      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom et choisir au moins un exercice.')),
      );
    }
  }

  Future<void> _addExercise() async {
    final selectedExercise = await Navigator.push<ExerciseItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddExerciseToSessionPage()),
    );
    if (selectedExercise != null) {
      setState(() => selectedExercises.add(selectedExercise));
    }
  }

  void _removeExercise(int index) {
    setState(() => selectedExercises.removeAt(index));
  }

  void _chooseImportMethod() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.white),
                title: const Text('Créer une séance personnalisée', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.directions_run, color: Colors.orangeAccent),
                title: const Text('Importer depuis Strava', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StravaImportPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chooseImportMethod());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Nouvelle séance'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nom de la séance',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un exercice'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedExercises.isEmpty
                    ? const Center(child: Text('Aucun exercice ajouté', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                  itemCount: selectedExercises.length,
                  itemBuilder: (context, index) {
                    final ex = selectedExercises[index];
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/images/${ex.image}'),
                        ),
                        title: Text(ex.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${ex.sets}x${ex.reps} - ${ex.weight} kg', style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _removeExercise(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _saveSession,
                icon: const Icon(Icons.check),
                label: const Text('Créer la séance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
