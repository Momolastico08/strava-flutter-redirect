// lib/pages/objectifs_nutritionnels_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObjectifsNutritionnelsPage extends StatefulWidget {
  const ObjectifsNutritionnelsPage({Key? key}) : super(key: key);

  @override
  State<ObjectifsNutritionnelsPage> createState() => _ObjectifsNutritionnelsPageState();
}

class _ObjectifsNutritionnelsPageState extends State<ObjectifsNutritionnelsPage> {
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesController.text = (prefs.getInt('goalCalories') ?? '').toString();
      _proteinsController.text = (prefs.getInt('goalProteins') ?? '').toString();
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    int? calories = int.tryParse(_caloriesController.text);
    int? proteins = int.tryParse(_proteinsController.text);

    if (calories != null) {
      await prefs.setInt('goalCalories', calories);
    }
    if (proteins != null) {
      await prefs.setInt('goalProteins', proteins);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Objectifs enregistrés avec succès !')),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs Nutritionnels')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Objectif Calories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Entrer un objectif calorique (kcal)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text(
              'Objectif Protéines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _proteinsController,
              decoration: const InputDecoration(
                labelText: 'Entrer un objectif protéiné (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
