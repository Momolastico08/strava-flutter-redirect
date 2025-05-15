import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/meal_model.dart';
import '../models/workout.dart';
import '../utils/pdf_export.dart';
import 'workout_ai_analysis.dart';
import 'package:fl_chart/fl_chart.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  double _weeklyCalories = 0;
  double _weeklyProteins = 0;
  int _hydration = 0;
  int _weight = 70;
  double _height = 175;
  int _workoutCount = 0;
  double _volume = 0;
  double _avgSleep = 7.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final meals = await DatabaseHelper.instance.getMeals();
    final workouts = await DatabaseHelper.instance.getWorkouts();

    final today = DateTime.now();
    final thisWeekStart = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));

    double kcal = 0, prot = 0, vol = 0;
    int count = 0;

    for (final m in meals) {
      if (m.date.isAfter(thisWeekStart) || m.date.isAtSameMomentAs(thisWeekStart)) {
        kcal += m.totalCalories;
        prot += m.totalProteins;
      }
    }

    for (final w in workouts) {
      if (w.date.isAfter(thisWeekStart) || w.date.isAtSameMomentAs(thisWeekStart)) {
        count++;
        vol += (w.reps * w.sets * w.weight).toDouble();
      }
    }

    final hydKey = 'hydrationToday_${today.year}-${today.month}-${today.day}';

    final rawWeight = prefs.get('weight');
    final rawHeight = prefs.get('height');
    final rawSleep = prefs.get('avgSleep');
    final rawHydration = prefs.get(hydKey);

    setState(() {
      _weeklyCalories = kcal;
      _weeklyProteins = prot;
      _workoutCount = count;
      _volume = vol;

      _hydration = rawHydration is int
          ? rawHydration
          : (rawHydration is double ? rawHydration.toInt() : 0);

      _weight = rawWeight is int
          ? rawWeight
          : (rawWeight is double ? rawWeight.toInt() : 70);

      _height = rawHeight is double
          ? rawHeight
          : (rawHeight is int ? rawHeight.toDouble() : 175);

      _avgSleep = rawSleep is double
          ? rawSleep
          : (rawSleep is int ? rawSleep.toDouble() : 7.0);
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.6), color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final avgCalories = _weeklyCalories / 7;
    final avgProteins = _weeklyProteins / 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1f4037), Color(0xFF99f2c8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📊 Moyennes journalières", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 2500,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Kcal', style: TextStyle(color: Colors.white));
                        case 1:
                          return const Text('Prot', style: TextStyle(color: Colors.white));
                        default:
                          return const SizedBox.shrink();
                      }
                    }),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: avgCalories,
                      color: Colors.orangeAccent,
                      width: 24,
                      borderRadius: BorderRadius.circular(6),
                    )
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: avgProteins * 10,
                      color: Colors.blueAccent,
                      width: 24,
                      borderRadius: BorderRadius.circular(6),
                    )
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        title: const Text('📊 Bilan hebdomadaire', style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildBarChart(),
                _buildStatCard('🍽️ Nutrition',
                    '${(_weeklyCalories / 7).toStringAsFixed(0)} kcal / jour\n${(_weeklyProteins / 7).toStringAsFixed(1)} g prot',
                    Icons.restaurant, Colors.orange, () {}),
                _buildStatCard('🏋️‍♂️ Musculation',
                    '$_workoutCount séances • ${_volume.toStringAsFixed(0)} pts', Icons.fitness_center, Colors.purple, () {}),
                _buildStatCard('💧 Hydratation', '$_hydration mL aujourd’hui', Icons.water_drop, Colors.teal, () {}),
                _buildStatCard('⚖️ Poids', '$_weight kg', Icons.monitor_weight, Colors.brown, () {}),
                _buildStatCard('🧠 Analyse IA', 'Voir les recommandations personnalisées', Icons.analytics, Colors.cyan, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutAIAnalysisPage()));
                }),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    generateWeeklyReportPdf(
                      context: context,
                      avgCalories: _weeklyCalories / 7,
                      avgProteins: _weeklyProteins / 7,
                      hydration: _hydration,
                      workoutCount: _workoutCount,
                      volume: _volume,
                      weight: _weight,
                      height: _height,
                      avgSleep: _avgSleep,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exporter la semaine en PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
