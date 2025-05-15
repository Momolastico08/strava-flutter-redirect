// lib/pages/nutrition_history_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_model.dart';
import '../services/database_helper.dart';
import 'meal_detail_page.dart';
import 'create_meal_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Meal> allMeals = [];
  Map<String, List<Meal>> groupedMeals = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final fetchedMeals = await DatabaseHelper.instance.getMeals();
    fetchedMeals.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      allMeals = fetchedMeals;
      _filterMeals();
    });
  }

  void _filterMeals() {
    final Map<String, List<Meal>> grouped = {};
    for (var meal in allMeals) {
      if (_searchQuery.isNotEmpty &&
          !meal.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }
      final dateKey = DateFormat('dd MMM yyyy').format(meal.date);
      grouped.putIfAbsent(dateKey, () => []).add(meal);
    }
    setState(() {
      groupedMeals = grouped;
    });
  }

  double _getTotalCalories(Meal meal) {
    return meal.items.fold(0.0, (sum, item) =>
    sum + (item.food.caloriesPer100g * item.quantity) / 100);
  }

  double _getTotalProteins(Meal meal) {
    return meal.items.fold(0.0, (sum, item) =>
    sum + (item.food.proteinsPer100g * item.quantity) / 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Ajouter un repas"),
          backgroundColor: Colors.orange,
          onPressed: () async {
            final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CreateMealPage()),
            );
            if (added == true) _loadMeals();
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        hintText: 'Rechercher un repas...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                          _filterMeals();
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: groupedMeals.isEmpty
                      ? const Center(
                    child: Text('Aucun repas trouvé',
                        style: TextStyle(color: Colors.white70)),
                  )
                      : ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: groupedMeals.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...entry.value.map((meal) {
                              final kcal = _getTotalCalories(meal)
                                  .toStringAsFixed(0);
                              final prot = _getTotalProteins(meal)
                                  .toStringAsFixed(1);
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                  Border.all(color: Colors.white24),
                                ),
                                child: ListTile(
                                  title: Text(meal.name,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                  subtitle: Text(
                                      '$kcal kcal • $prot g prot',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MealDetailPage(meal: meal),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
