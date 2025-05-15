import 'package:flutter/material.dart';
import '../models/exercise_item.dart';
import '../services/database_helper.dart';

class CategoryExercisesPage extends StatefulWidget {
  final String category;

  const CategoryExercisesPage({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryExercisesPage> createState() => _CategoryExercisesPageState();
}

class _CategoryExercisesPageState extends State<CategoryExercisesPage> {
  List<ExerciseItem> allExercises = [];
  List<ExerciseItem> filteredExercises = [];
  String selectedSubCategory = 'Tous';
  String searchQuery = '';
  String sortOption = 'Nom';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final all = await DatabaseHelper.instance.getExercises();
    final cat = widget.category.toLowerCase();
    setState(() {
      allExercises = all.where((e) => e.category.toLowerCase() == cat).toList();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<ExerciseItem> filtered = List.from(allExercises);

    if (selectedSubCategory != 'Tous') {
      filtered = filtered.where((e) => e.muscleGroup.toLowerCase().contains(selectedSubCategory.toLowerCase())).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((e) => e.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    if (sortOption == 'Nom') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (sortOption == 'Poids') {
      filtered.sort((a, b) => a.weight.compareTo(b.weight));
    }

    setState(() {
      filteredExercises = filtered;
    });
  }

  void _filterBySubCategory(String sub) {
    setState(() {
      selectedSubCategory = sub;
    });
    _applyFilters();
  }

  void _customizeExercise(ExerciseItem baseExercise) {
    final setsController = TextEditingController(text: baseExercise.sets.toString());
    final repsController = TextEditingController(text: baseExercise.reps.toString());
    final weightController = TextEditingController(text: baseExercise.weight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurer "${baseExercise.name}"'),
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
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Ajouter'),
            onPressed: () {
              final customized = ExerciseItem(
                id: baseExercise.id,
                name: baseExercise.name,
                sets: int.tryParse(setsController.text) ?? baseExercise.sets,
                reps: int.tryParse(repsController.text) ?? baseExercise.reps,
                weight: double.tryParse(weightController.text) ?? baseExercise.weight,
                muscleGroup: baseExercise.muscleGroup,
                category: baseExercise.category,
                image: baseExercise.image,
              );
              Navigator.pop(context);
              Navigator.pop(context, customized);
            },
          ),
        ],
      ),
    );
  }

  Map<String, List<ExerciseItem>> _groupByMuscleGroup(List<ExerciseItem> list) {
    final map = <String, List<ExerciseItem>>{};
    for (var ex in list) {
      final group = ex.muscleGroup;
      if (!map.containsKey(group)) {
        map[group] = [];
      }
      map[group]!.add(ex);
    }
    return map;
  }

  List<Widget> _buildGroupedList() {
    final grouped = _groupByMuscleGroup(filteredExercises);
    return grouped.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...entry.value.map((ex) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/${ex.image}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(ex.name),
              subtitle: Text('${ex.sets}x${ex.reps} - ${ex.weight} kg'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _customizeExercise(ex),
              ),
            ),
          ))
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final subCategories = ['Tous'];
    subCategories.addAll({
      for (var e in allExercises)
        if (!subCategories.contains(e.muscleGroup.split(' - ').last))
          e.muscleGroup.split(' - ').last
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Exercices - ${widget.category}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => sortOption = value);
              _applyFilters();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'Nom', child: Text('Trier par nom')),
              const PopupMenuItem(value: 'Poids', child: Text('Trier par poids')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
                _applyFilters();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un exercice...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
          ),
          if (widget.category.toLowerCase() == 'salle')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: subCategories.map((sub) {
                  final selected = sub == selectedSubCategory;
                  return ChoiceChip(
                    label: Text(sub),
                    selected: selected,
                    onSelected: (_) => _filterBySubCategory(sub),
                    selectedColor: Colors.deepOrangeAccent,
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: filteredExercises.isEmpty
                ? const Center(child: Text('Aucun exercice trouvé'))
                : ListView(children: _buildGroupedList()),
          ),
        ],
      ),
    );
  }
}
