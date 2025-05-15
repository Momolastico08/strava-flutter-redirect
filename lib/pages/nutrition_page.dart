import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/meal_model.dart';
import 'create_meal_page.dart';
import 'meal_detail_page.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  List<Meal> allMeals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final fetchedMeals = await DatabaseHelper.instance.getMeals();
    fetchedMeals.sort((a, b) => b.date.compareTo(a.date));
    setState(() => allMeals = fetchedMeals);
  }

  List<Meal> _filterMeals(String filter) {
    final now = DateTime.now();
    if (filter == 'jour') {
      return allMeals.where((m) =>
      m.date.day == now.day &&
          m.date.month == now.month &&
          m.date.year == now.year).toList();
    } else if (filter == 'semaine') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return allMeals.where((m) => m.date.isAfter(startOfWeek)).toList();
    } else {
      return allMeals.where((m) => m.date.month == now.month).toList();
    }
  }

  Widget _buildMealList(List<Meal> meals) {
    if (meals.isEmpty) {
      return const Center(
        child: Text('Aucun repas trouvé', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: meals.length,
      itemBuilder: (ctx, i) {
        final meal = meals[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: ListTile(
            title: Text(meal.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${meal.items.length} aliment(s) • ${meal.totalCalories.toStringAsFixed(0)} kcal',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Text(
              '${meal.date.day}/${meal.date.month}/${meal.date.year}',
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealDetailPage(meal: meal),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un repas'),
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
        appBar: AppBar(
          title: const Text('Nutrition'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: 'Jour'),
              Tab(text: 'Semaine'),
              Tab(text: 'Mois'),
            ],
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
              child: TabBarView(
                children: [
                  _buildMealList(_filterMeals('jour')),
                  _buildMealList(_filterMeals('semaine')),
                  _buildMealList(_filterMeals('mois')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
