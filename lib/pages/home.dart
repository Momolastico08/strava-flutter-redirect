import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'profil_page.dart';
import 'objectifs_nutritionnels_page.dart';
import '../services/database_helper.dart';
import '../models/meal_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _dayCompleted = true;
  double _totalCalories = 0;
  double _totalProteins = 0;
  int _totalWorkouts = 0;
  int _goalCalories = 2000;
  int _goalProteins = 100;
  int _hydrationMl = 0;
  int _hydrationGoal = 2000;
  int _weight = 70;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _checkDayCompletion();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {});
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkDayCompletion() async {
    final prefs = await SharedPreferences.getInstance();

    final rawGoalCalories = prefs.get('goalCalories');
    final rawGoalProteins = prefs.get('goalProteins');
    final rawHydrationGoal = prefs.get('hydrationGoal');
    final rawWeight = prefs.get('weight');
    final hydrationToday = prefs.get('hydrationToday_${_getTodayKey()}');

    _goalCalories = (rawGoalCalories is int)
        ? rawGoalCalories
        : (rawGoalCalories is double)
        ? rawGoalCalories.toInt()
        : 2000;

    _goalProteins = (rawGoalProteins is int)
        ? rawGoalProteins
        : (rawGoalProteins is double)
        ? rawGoalProteins.toInt()
        : 100;

    _hydrationGoal = (rawHydrationGoal is int)
        ? rawHydrationGoal
        : (rawHydrationGoal is double)
        ? rawHydrationGoal.toInt()
        : 2000;

    _weight = (rawWeight is int)
        ? rawWeight
        : (rawWeight is double)
        ? rawWeight.toInt()
        : 70;

    _hydrationMl = (hydrationToday is int)
        ? hydrationToday
        : (hydrationToday is double)
        ? hydrationToday.toInt()
        : 0;

    final todayMeals = await DatabaseHelper.instance.getMeals();
    final todayWorkouts = await DatabaseHelper.instance.getWorkouts();
    final today = DateTime.now();

    double totalCalories = 0;
    double totalProteins = 0;
    int totalWorkouts = 0;

    for (var meal in todayMeals) {
      if (isSameDay(meal.date, today)) {
        for (var item in meal.items) {
          totalCalories += (item.food.caloriesPer100g * item.quantity) / 100;
          totalProteins += (item.food.proteinsPer100g * item.quantity) / 100;
        }
      }
    }

    for (var workout in todayWorkouts) {
      if (isSameDay(workout.date, today)) {
        totalWorkouts++;
      }
    }

    final completed = totalCalories >= _goalCalories && totalProteins >= _goalProteins;

    setState(() {
      _dayCompleted = completed;
      _totalCalories = totalCalories;
      _totalProteins = totalProteins;
      _totalWorkouts = totalWorkouts;
    });
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'profile') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilPage()))
          .then((_) => _checkDayCompletion());
    } else if (value == 'objectifs') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ObjectifsNutritionnelsPage()))
          .then((_) => _checkDayCompletion());
    }
  }

  void _showHydrationDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.grey[900],
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajouter de l\'eau 💧', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [250, 500, 750].map((amount) {
                  return ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final key = 'hydrationToday_${_getTodayKey()}';
                      final updated = (_hydrationMl + amount).clamp(0, 5000);
                      await prefs.setInt(key, updated);
                      setState(() => _hydrationMl = updated);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text('+${amount} mL'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final controller = TextEditingController(text: '$_hydrationGoal');
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Modifier l\'objectif'),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Objectif en mL'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final val = int.tryParse(controller.text.trim());
                    if (val != null && val > 0) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('hydrationGoal', val);
                      setState(() => _hydrationGoal = val);
                    }
                  }
                },
                child: const Text('Modifier mon objectif 💦', style: TextStyle(color: Colors.teal)),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 36) / 2;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
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
          MediaQuery.removePadding(
            context: context,
            removeTop: false,
            removeBottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildCustomAppBar(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildCard('Calories', '$_totalCalories kcal / $_goalCalories kcal', Colors.orange, Icons.local_fire_department, cardWidth),
                      _buildCard('Protéines', '$_totalProteins g / $_goalProteins g', Colors.green, Icons.fitness_center, cardWidth),
                      _buildCard('Exercices', '$_totalWorkouts', Colors.purple, Icons.directions_run, cardWidth),
                      _buildCard('Sommeil', '8 h', Colors.blue, Icons.bedtime, cardWidth),
                      _buildCard('Hydratation', '$_hydrationMl mL / $_hydrationGoal mL', Colors.teal, Icons.local_drink, cardWidth, onTap: _showHydrationDialog),
                      _buildCard('Poids actuel', '$_weight kg', Colors.brown, Icons.monitor_weight, cardWidth),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/avatar.png'),
                radius: 16,
              ),
              onSelected: (value) => _handleMenuSelection(context, value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'profile', child: Text('Voir Profil')),
                PopupMenuItem(value: 'objectifs', child: Text('Objectifs Nutritionnels')),
              ],
            ),
            const Text('Accueil', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_dayCompleted
                            ? 'Objectifs atteints aujourd\'hui 🎉'
                            : 'Objectifs non atteints'),
                      ),
                    );
                  },
                ),
                Icon(Icons.circle, size: 12, color: _dayCompleted ? Colors.green : Colors.red),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String label, String value, Color color, IconData icon, double width, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
