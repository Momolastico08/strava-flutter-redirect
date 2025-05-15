// lib/pages/day_summary_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/meal_model.dart';

class DaySummaryPage extends StatefulWidget {
  const DaySummaryPage({Key? key}) : super(key: key);

  @override
  State<DaySummaryPage> createState() => _DaySummaryPageState();
}

class _DaySummaryPageState extends State<DaySummaryPage> {
  int goalCalories = 0;
  int goalProteins = 0;
  double consumedCalories = 0;
  double consumedProteins = 0;
  List<Meal> todayMeals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    goalCalories = prefs.getInt('goalCalories') ?? 2000;
    goalProteins = prefs.getInt('goalProteins') ?? 100;

    final allMeals = await DatabaseHelper.instance.getMeals();
    final today = DateTime.now();

    consumedCalories = 0;
    consumedProteins = 0;
    todayMeals = [];

    for (var meal in allMeals) {
      if (meal.date.year == today.year &&
          meal.date.month == today.month &&
          meal.date.day == today.day) {

        todayMeals.add(meal);

        for (var item in meal.items) {
          consumedCalories += (item.food.caloriesPer100g * item.quantity) / 100;
          consumedProteins += (item.food.proteinsPer100g * item.quantity) / 100;
        }
      }
    }

    setState(() {});
  }

  double _calculateProgress(double consumed, int goal) {
    if (goal == 0) return 0;
    return (consumed / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé de la journée'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aujourd\'hui : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _buildProgressCard(
              title: 'Calories',
              consumed: consumedCalories,
              goal: goalCalories.toDouble(),
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            _buildProgressCard(
              title: 'Protéines',
              consumed: consumedProteins,
              goal: goalProteins.toDouble(),
              color: Colors.green,
            ),
            const SizedBox(height: 30),
            if (todayMeals.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: todayMeals.length,
                  itemBuilder: (context, index) {
                    final meal = todayMeals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(meal.name),
                        subtitle: Text(
                          '${meal.items.length} aliments - ${meal.date.hour}h${meal.date.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (todayMeals.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Aucun repas enregistré aujourd\'hui.'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required double consumed,
    required double goal,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title : ${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _calculateProgress(consumed, goal.toInt()),
              minHeight: 12,
              color: color,
              backgroundColor: color.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
