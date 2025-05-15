import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/workout.dart';
import 'setup_questionnaire.dart';
import 'package:intl/intl.dart';
import 'dart:collection';
import 'package:share_plus/share_plus.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String gender = '';
  int age = 0;
  int height = 0;
  int weight = 0;
  String goal = '';
  String? avatarPath;
  int totalWorkouts = 0;
  double totalVolume = 0.0;
  DateTime? lastWorkoutDate;
  double workoutsPerWeek = 0.0;
  String motivation = '';
  String accountCreationDate = '';
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final workouts = await DatabaseHelper.instance.getWorkouts();

    double volume = 0;
    DateTime? lastDate;
    final dateMap = <String, int>{};

    for (var w in workouts) {
      final wVolume = w.sets * w.reps * w.weight;
      volume += wVolume;
      lastDate ??= w.date;
      if (w.date.isAfter(lastDate)) lastDate = w.date;
      final weekKey = '${w.date.year}-W${_getWeekNumber(w.date)}';
      dateMap[weekKey] = (dateMap[weekKey] ?? 0) + 1;
    }

    if (!prefs.containsKey('accountCreationDate')) {
      prefs.setString('accountCreationDate', DateFormat('yyyy-MM-dd').format(DateTime.now()));
    }

    setState(() {
      gender = prefs.getString('gender') ?? '';
      age = prefs.getInt('age') ?? 0;
      height = prefs.getInt('height') ?? 0;
      weight = prefs.getInt('weight') ?? 0;
      goal = prefs.getString('goal') ?? '';
      motivation = prefs.getString('motivation') ?? '';
      accountCreationDate = prefs.getString('accountCreationDate') ?? '';
      _motivationController.text = motivation;
      avatarPath = prefs.getString('avatarPath');
      totalWorkouts = workouts.length;
      totalVolume = volume;
      lastWorkoutDate = lastDate;
      workoutsPerWeek = dateMap.isEmpty ? 0 : totalWorkouts / dateMap.length;
    });
  }

  int _getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final daysOffset = firstDay.weekday - 1;
    final firstMonday = firstDay.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil();
  }

  String _getBadge() {
    if (totalWorkouts >= 100) return '🏆 Légende';
    if (totalWorkouts >= 30) return '🥇 Or';
    if (totalWorkouts >= 15) return '🥈 Argent';
    if (totalWorkouts >= 5) return '🥉 Bronze';
    return 'Débutant';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatarPath', pickedFile.path);
      setState(() => avatarPath = pickedFile.path);
    }
  }

  void _modifyProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetupQuestionnairePage()),
    );
    if (updated == true) {
      _loadProfile();
    }
  }

  void _updateWeight() async {
    final newWeight = double.tryParse(_weightController.text);
    if (newWeight != null) {
      final prefs = await SharedPreferences.getInstance();
      final weightEntries = prefs.getStringList('weightHistory') ?? [];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      weightEntries.add('$today|$newWeight');
      await prefs.setStringList('weightHistory', weightEntries);
      await prefs.setInt('weight', newWeight.toInt());
      _loadProfile();
      _weightController.clear();
    }
  }

  void _saveMotivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('motivation', _motivationController.text.trim());
    setState(() => motivation = _motivationController.text.trim());
  }

  void _exportProfile() {
    final exportText = '''🧍 Profil Muscu Tracker
Nom: $gender
Âge: $age ans
Taille: $height cm
Poids: $weight kg
Objectif: $goal
Motivation: $motivation
Total séances: $totalWorkouts
Volume total: ${totalVolume.toStringAsFixed(0)} kg
Dernière séance: ${lastWorkoutDate != null ? DateFormat('dd/MM/yyyy').format(lastWorkoutDate!) : 'Aucune'}
Créé le: $accountCreationDate
''';
    Share.share(exportText);
  }

  @override
  Widget build(BuildContext context) {
    final bool avatarExists = avatarPath != null && File(avatarPath!).existsSync();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportProfile,
          )
        ],
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
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: avatarExists
                              ? FileImage(File(avatarPath!))
                              : const AssetImage('assets/images/avatar.png') as ImageProvider,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _getBadge(),
                          key: ValueKey(_getBadge()),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassSection(title: "🧍 Infos personnelles", children: [
                      _buildProfileLine('Genre', gender),
                      _buildProfileLine('Âge', '$age ans'),
                      _buildProfileLine('Taille', '$height cm'),
                      _buildProfileLine('Objectif', goal),
                      _buildProfileLine('Date de création', accountCreationDate),
                    ]),
                    const SizedBox(height: 16),
                    _buildGlassSection(title: "💬 Ma motivation", children: [
                      TextField(
                        controller: _motivationController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ex: Atteindre mon meilleur niveau',
                          hintStyle: const TextStyle(color: Colors.white60),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save, color: Colors.white),
                            onPressed: _saveMotivation,
                          ),
                        ),
                      )
                    ]),
                    const SizedBox(height: 16),
                    _buildGlassSection(title: "⚖️ Suivi du poids", children: [
                      _buildProfileLine('Poids', '$weight kg'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Poids actuel (kg)',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _updateWeight,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.orangeAccent,
                            ),
                            child: const Text('Ajouter'),
                          )
                        ],
                      )
                    ]),
                    const SizedBox(height: 16),
                    _buildGlassSection(title: "📊 Activité", children: [
                      _buildProfileLine('Total Volume', '${totalVolume.toStringAsFixed(0)} kg'),
                      _buildProfileLine('Dernière séance',
                          lastWorkoutDate != null ? DateFormat('dd/MM/yyyy').format(lastWorkoutDate!) : 'Aucune'),
                      _buildProfileLine('Séances/semaine', workoutsPerWeek.toStringAsFixed(1)),
                    ]),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _modifyProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier le profil'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGlassSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
