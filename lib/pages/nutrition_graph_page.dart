// lib/pages/nutrition_graph_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';
import '../models/meal_model.dart';
import 'package:intl/intl.dart';

class NutritionGraphPage extends StatefulWidget {
  const NutritionGraphPage({Key? key}) : super(key: key);

  @override
  State<NutritionGraphPage> createState() => _NutritionGraphPageState();
}

class _NutritionGraphPageState extends State<NutritionGraphPage> {
  late Future<List<Meal>> _futureMeals;
  String _filter = 'jour'; // jour ou semaine

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  void _loadMeals() {
    _futureMeals = DatabaseHelper.instance.getMeals();
  }

  Map<String, double> _computeTotals(List<Meal> meals) {
    double totalCalories = 0;
    double totalProteins = 0;

    final now = DateTime.now();

    for (var meal in meals) {
      if (_filter == 'jour') {
        if (meal.date.year == now.year && meal.date.month == now.month && meal.date.day == now.day) {
          totalCalories += meal.totalCalories;
          totalProteins += meal.totalProteins;
        }
      } else if (_filter == 'semaine') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        if (meal.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
          totalCalories += meal.totalCalories;
          totalProteins += meal.totalProteins;
        }
      }
    }

    return {
      'Calories': totalCalories,
      'Protéines': totalProteins,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: ToggleButtons(
            isSelected: [
              _filter == 'jour',
              _filter == 'semaine',
            ],
            onPressed: (index) {
              setState(() {
                if (index == 0) _filter = 'jour';
                if (index == 1) _filter = 'semaine';
              });
            },
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: Colors.orange,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Jour'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Semaine'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Meal>>(
            future: _futureMeals,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final meals = snapshot.data ?? [];
              final totals = _computeTotals(meals);

              if (totals['Calories'] == 0 && totals['Protéines'] == 0) {
                return const Center(child: Text('Pas de données.'));
              }

              return PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.orange,
                      value: totals['Calories'],
                      title: '${totals['Calories']!.toStringAsFixed(0)} kcal',
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    PieChartSectionData(
                      color: Colors.blue,
                      value: totals['Protéines'],
                      title: '${totals['Protéines']!.toStringAsFixed(0)}g prot',
                      radius: 80,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
