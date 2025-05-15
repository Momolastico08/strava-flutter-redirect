// 📁 workout_ai_analysis.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/meal_model.dart';
import '../models/workout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/pdf_export.dart';

class WorkoutAIAnalysisPage extends StatefulWidget {
  const WorkoutAIAnalysisPage({super.key});

  @override
  State<WorkoutAIAnalysisPage> createState() => _WorkoutAIAnalysisPageState();
}

class _WorkoutAIAnalysisPageState extends State<WorkoutAIAnalysisPage> {
  double _avgCalories = 0;
  double _avgProteins = 0;
  int _hydration = 0;
  int _weight = 70;
  int _age = 20;
  int _height = 175;
  int _workoutCount = 0;
  double _volume = 0;
  double _sleepHours = 0;
  double _score = 0;
  String _objective = 'prise de masse';
  String selectedPeriod = 'Cette semaine';
  bool recommendationsValidated = false;

  final Map<String, List<double>> weeklyMuscleProgress = {
    'Pecs': [5000, 6000, 6500, 7000, 8000, 8200],
    'Dos': [9000, 9500, 10000, 10500, 11000, 12000],
    'Jambes': [3000, 2800, 2600, 2900, 3100, 3000],
    'Bras': [7000, 7200, 7500, 7800, 8500, 9000],
    'Épaules': [2000, 2200, 2400, 2500, 2700, 3000],
    'Abdos': [1000, 1200, 1300, 1500, 1600, 1700],
  };

  List<double> calorieHistory = List.filled(7, 0);
  List<double> proteinHistory = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    DateTime startDate;
    int totalDays = 7;

    if (selectedPeriod == 'Cette semaine') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      totalDays = 7;
    } else if (selectedPeriod == 'Semaine dernière') {
      startDate = now.subtract(Duration(days: now.weekday + 6));
      totalDays = 7;
    } else {
      startDate = DateTime(now.year, now.month - 1, now.day);
      totalDays = 30;
    }

    final meals = await DatabaseHelper.instance.getMeals();
    final workouts = await DatabaseHelper.instance.getWorkouts();

    double kcal = 0, prot = 0, vol = 0;
    int count = 0;
    final dailyCalories = List<double>.filled(7, 0);
    final dailyProteins = List<double>.filled(7, 0);

    for (final m in meals) {
      if (!m.date.isBefore(startDate)) {
        final dayIndex = m.date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyCalories[dayIndex] += m.totalCalories;
          dailyProteins[dayIndex] += m.totalProteins;
        }
        kcal += m.totalCalories;
        prot += m.totalProteins;
      }
    }

    for (final w in workouts) {
      if (!w.date.isBefore(startDate)) {
        vol += (w.reps * w.sets * w.weight).toDouble();
        count++;
      }
    }

    final hydrationKey = 'hydrationToday_${now.year}-${now.month}-${now.day}';
    final sleepKey = 'sleepToday_${now.year}-${now.month}-${now.day}';

    setState(() {
      _avgCalories = totalDays > 0 ? kcal / totalDays : 0;
      _avgProteins = totalDays > 0 ? prot / totalDays : 0;
      _workoutCount = count;
      _volume = vol;
      _hydration = prefs.getInt(hydrationKey) ?? 0;
      _sleepHours = prefs.getDouble(sleepKey) ?? 0;
      _weight = prefs.getInt('weight') ?? 70;
      _age = prefs.getInt('age') ?? 20;
      _height = prefs.getInt('height') ?? 175;
      _objective = prefs.getString('objective') ?? 'prise de masse';
      recommendationsValidated = prefs.getBool('recommendationsValidated_$selectedPeriod') ?? false;
      _score = _calculateScore();
      calorieHistory = dailyCalories;
      proteinHistory = dailyProteins;
    });
  }

  double _calculateScore() {
    double score = 0;
    if (_avgCalories >= 1800) score += 25;
    if (_avgProteins >= 1.5 * _weight) score += 20;
    if (_hydration >= _weight * 35) score += 15;
    if (_workoutCount >= 3) score += 25;
    if (_sleepHours >= 7) score += 10;
    return score;
  }

  String _getUserLevel() {
    if (_score >= 80) return "Athlète 🔥";
    if (_score >= 50) return "Intermédiaire 💪";
    return "Débutant 🏁";
  }

  String _generateIASummary() {
    String summary = "";
    summary += _workoutCount >= 3 ? "✔️ Bonne régularité d'entraînement.\n" : "⚠️ Entraînements insuffisants.\n";
    summary += _avgProteins >= 1.5 * _weight ? "✔️ Apport en protéines suffisant.\n" : "⚠️ Apport en protéines à améliorer.\n";
    summary += _hydration >= _weight * 35 ? "✔️ Bonne hydratation.\n" : "⚠️ Hydratation insuffisante.\n";
    summary += _sleepHours >= 7 ? "✔️ Sommeil optimal.\n" : "⚠️ Manque de sommeil.\n";
    return summary;
  }

  String _analyzeTrend(List<double> values) {
    final diff = values.last - values.first;
    if (diff > 500) return "📈 Progression";
    if (diff < -500) return "📉 Régression";
    return "⏸️ Stagnation";
  }

  Widget buildScoreBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget buildNutritionChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text('J${value.toInt() + 1}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(calorieHistory.length, (i) => FlSpot(i.toDouble(), calorieHistory[i])),
              isCurved: true,
              color: Colors.orange,
              barWidth: 2,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: List.generate(proteinHistory.length, (i) => FlSpot(i.toDouble(), proteinHistory[i])),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMuscleChart(String muscle, List<double> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📊 $muscle', style: const TextStyle(color: Colors.white)),
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
                  isCurved: true,
                  color: Colors.cyan,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                )
              ],
              titlesData: FlTitlesData(show: false),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        )
      ],
    );
  }

  Widget buildInteractiveCard({required String title, required String content, required Widget child}) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
      child: Card(
        color: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  Widget buildBadges() {
    List<Widget> badges = [];
    if (_workoutCount >= 3) badges.add(const Chip(label: Text('🏋️ Régularité')));
    if (_avgProteins >= 1.5 * _weight) badges.add(const Chip(label: Text('🥚 Protéiné')));
    if (_score >= 90) badges.add(const Chip(label: Text('🔥 Excellence')));
    if (_hydration >= _weight * 35) badges.add(const Chip(label: Text('💧 Hydraté')));
    badges.add(const Chip(label: Text('🧾 Suivi exemplaire')));
    return Wrap(spacing: 8, runSpacing: 4, children: badges);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Analyse complète IA'),
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedPeriod,
            onSelected: (value) {
              setState(() => selectedPeriod = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Cette semaine', child: Text('Cette semaine')),
              const PopupMenuItem(value: 'Semaine dernière', child: Text('Semaine dernière')),
              const PopupMenuItem(value: 'Mois dernier', child: Text('Mois dernier')),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Score global : ${_score.toStringAsFixed(0)} / 100",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _score >= 80 ? Colors.green : (_score >= 50 ? Colors.orange : Colors.red))),
            const SizedBox(height: 8),
            Text("Niveau actuel : ${_getUserLevel()}", style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 24),
            const Text('🏅 Badges débloqués', style: TextStyle(color: Colors.white, fontSize: 16)),
            buildBadges(),
            const SizedBox(height: 24),
            buildInteractiveCard(
              title: '🧠 Synthèse IA',
              content: _generateIASummary(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧠 Synthèse IA intelligente', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(_generateIASummary(), style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            buildInteractiveCard(
              title: '🎯 Score par catégorie',
              content: 'Détail nutrition, protéines, hydratation, entraînement et sommeil.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildScoreBar('Nutrition', (_avgCalories / 2200) * 100, Colors.orange),
                  buildScoreBar('Protéines', (_avgProteins / (_weight * 1.5)) * 100, Colors.blue),
                  buildScoreBar('Hydratation', (_hydration / (_weight * 35)) * 100, Colors.teal),
                  buildScoreBar('Entraînement', (_workoutCount / 5) * 100, Colors.purple),
                  buildScoreBar('Sommeil', (_sleepHours / 8) * 100, Colors.indigo),
                ],
              ),
            ),
            const SizedBox(height: 32),
            buildInteractiveCard(
              title: '📈 Évolution nutritionnelle',
              content: 'Calories (orange) / Protéines (bleu)',
              child: buildNutritionChart(),
            ),
            const SizedBox(height: 32),
            const Text('📈 Groupes musculaires – Évolution', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ...weeklyMuscleProgress.entries.map((e) => buildInteractiveCard(
              title: 'Évolution ${e.key}',
              content: _analyzeTrend(e.value),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMuscleChart(e.key, e.value),
                  const SizedBox(height: 6),
                  Text(_analyzeTrend(e.value), style: const TextStyle(color: Colors.white60)),
                ],
              ),
            )),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                generateWeeklyReportPdf(
                  context: context, // ✅ Correction ici
                  avgCalories: _avgCalories,
                  avgProteins: _avgProteins,
                  hydration: _hydration,
                  workoutCount: _workoutCount,
                  volume: _volume,
                  weight: _weight,
                  height: _height.toDouble(),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Exporter l’analyse en PDF"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            ),
          ],
        ),
      ),
    );
  }
}
