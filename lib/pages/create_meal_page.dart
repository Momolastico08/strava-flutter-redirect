import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import '../models/meal_model.dart';
import '../services/database_helper.dart';
import 'scan_food_page.dart';

class CreateMealPage extends StatefulWidget {
  final Meal? existingMeal;
  const CreateMealPage({super.key, this.existingMeal});

  @override
  State<CreateMealPage> createState() => _CreateMealPageState();
}

class _CreateMealPageState extends State<CreateMealPage> {
  List<Food> foods = [];
  final Map<Food, int> quantities = {};
  bool isLoading = true;
  String mealName = '';
  String _search = '';
  String _selectedCategory = 'Tous';
  int caloriesGoal = 2000;
  int proteinsGoal = 150;

  final List<String> _categories = [
    'Tous', 'Féculents', 'Légumes', 'Protéines', 'Produits laitiers', 'Autre',
  ];

  final Map<String, List<String>> _categoryKeywords = {
    'Féculents': ['riz', 'pâtes', 'patate', 'pain', 'quinoa'],
    'Légumes': ['brocoli', 'carotte', 'haricot', 'légume'],
    'Protéines': ['poulet', 'œuf', 'viande', 'thon', 'steak', 'jambon'],
    'Produits laitiers': ['fromage', 'skyr', 'yaourt', 'lait'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoals();
      _loadFoods();
    });
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    caloriesGoal = prefs.getInt('caloriesGoal') ?? 2000;
    proteinsGoal = prefs.getInt('proteinsGoal') ?? 150;
  }

  Future<void> _loadFoods() async {
    final data = await rootBundle.loadString('assets/data/foods.json');
    final List<dynamic> list = json.decode(data);
    final loadedFoods = list.map((e) => Food.fromJson(e)).toList();

    final localQuantities = <Food, int>{};
    for (var f in loadedFoods) {
      localQuantities[f] = 0;
    }

    if (widget.existingMeal != null) {
      final meal = widget.existingMeal!;
      mealName = meal.name;
      for (var item in meal.items) {
        final matchingFood = loadedFoods.firstWhere(
              (f) => f.name == item.food.name,
          orElse: () => item.food,
        );
        localQuantities[matchingFood] = item.quantity;
      }
    }

    setState(() {
      foods = loadedFoods;
      quantities.clear();
      quantities.addAll(localQuantities);
      isLoading = false;
    });
  }

  double get totalCalories => quantities.entries.map((e) => (e.key.caloriesPer100g * e.value) / 100).fold(0.0, (a, b) => a + b);
  double get totalProteins => quantities.entries.map((e) => (e.key.proteinsPer100g * e.value) / 100).fold(0.0, (a, b) => a + b);

  void _askMealNameAndSave() async {
    final controller = TextEditingController(text: mealName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nom du repas'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'ex: Déjeuner muscu'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Valider')),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final items = quantities.entries
          .where((e) => e.value > 0)
          .map((e) => MealItem(food: e.key, quantity: e.value))
          .toList();

      final meal = Meal(
        id: widget.existingMeal?.id,
        name: controller.text.trim(),
        date: DateTime.now(),
        items: items,
      );

      if (meal.id != null) {
        await DatabaseHelper.instance.updateMeal(meal);
      } else {
        await DatabaseHelper.instance.insertMeal(meal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Repas enregistré')));
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = _selectedCategory == 'Tous'
        ? foods.where((f) => f.name.toLowerCase().contains(_search.toLowerCase())).toList()
        : foods.where((f) {
      final keywords = _categoryKeywords[_selectedCategory] ?? [];
      return keywords.any((kw) => f.name.toLowerCase().contains(kw)) &&
          f.name.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Créer un repas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => setState(() => quantities.updateAll((key, _) => 0)), icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const ScanFoodPage()),
              );
              if (result != null) {
                final newFood = Food(
                  name: result['name'] ?? 'Aliment scanné',
                  caloriesPer100g: result['calories']?.toInt() ?? 0,
                  proteinsPer100g: result['proteins']?.toInt() ?? 0,
                  carbsPer100g: result['carbs']?.toInt() ?? 0,
                  fatsPer100g: result['fats']?.toInt() ?? 0,
                  image: 'default_food.png',
                );
                setState(() {
                  foods.add(newFood);
                  quantities[newFood] = 100;
                });
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un aliment...',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(color: Colors.white)),
                  selected: _selectedCategory == cat,
                  selectedColor: Colors.orange,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final food = filteredFoods[index];
                return Card(
                  color: Colors.white10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/${food.image}'),
                    ),
                    title: Text(food.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${food.caloriesPer100g} kcal • ${food.proteinsPer100g}g prot', style: const TextStyle(color: Colors.white70)),
                    trailing: TextButton(
                      onPressed: () => _openQuantitySelector(food),
                      child: const Text('Ajouter', style: TextStyle(color: Colors.orange)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: totalCalories > 0
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _askMealNameAndSave,
          icon: const Icon(Icons.check),
          label: Text('Enregistrer (${totalCalories.toStringAsFixed(0)} kcal, ${totalProteins.toStringAsFixed(1)}g prot)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      )
          : null,
    );
  }

  void _openQuantitySelector(Food food) {
    int selectedQuantity = quantities[food] ?? 100;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quantité pour ${food.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: selectedQuantity.toDouble(),
              min: 0,
              max: 500,
              divisions: 100,
              label: '$selectedQuantity g',
              onChanged: (value) => setState(() => selectedQuantity = value.toInt()),
            ),
            Text('$selectedQuantity g')
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() => quantities[food] = selectedQuantity);
              Navigator.pop(context);
            },
            child: const Text('Valider'),
          )
        ],
      ),
    );
  }
}
