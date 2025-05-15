// lib/pages/meal_detail_page.dart

import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/database_helper.dart';
import 'create_meal_page.dart';

class MealDetailPage extends StatefulWidget {
  final Meal meal;

  const MealDetailPage({Key? key, required this.meal}) : super(key: key);

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveChanges(Function action) async {
    setState(() {
      _isLoading = true;
    });
    await action();
    setState(() {
      _isLoading = false;
    });
    _showSnackBar('Modifications enregistrées.');
  }

  void _showEditAlimentBottomSheet(BuildContext context, int index) {
    final TextEditingController quantityController = TextEditingController(
      text: widget.meal.items[index].quantity.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Modifier ${widget.meal.items[index].food.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité (en grammes)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _saveChanges(() async {
                          widget.meal.items.removeAt(index);
                          await DatabaseHelper.instance.updateMeal(widget.meal);
                          setState(() {});
                          Navigator.pop(context);
                        }),
                        child: const Text('Supprimer'),
                      ),
                      ElevatedButton(
                        onPressed: () => _saveChanges(() async {
                          final newQuantity = double.tryParse(quantityController.text);
                          if (newQuantity != null && newQuantity > 0) {
                            setState(() {
                              final item = widget.meal.items[index];
                              widget.meal.items[index] = MealItem(
                                food: item.food,
                                quantity: newQuantity.toInt(),
                              );
                            });
                            await DatabaseHelper.instance.updateMeal(widget.meal);
                            Navigator.pop(context);
                          }
                        }),
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editMealName(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: widget.meal.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom du repas'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final updatedMeal = Meal(
                  id: widget.meal.id,
                  name: newName,
                  date: widget.meal.date,
                  items: widget.meal.items,
                );
                await DatabaseHelper.instance.updateMeal(updatedMeal);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MealItem>> grouped = {};
    for (var item in widget.meal.items) {
      final category = item.food.category ?? 'Autre';
      grouped.putIfAbsent(category, () => []).add(item);
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _editMealName(context),
              child: Text(widget.meal.name),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer le repas ?'),
                      content: const Text('Veux-tu vraiment supprimer ce repas ? Cette action est irréversible.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await DatabaseHelper.instance.deleteMeal(widget.meal.id!);
                    if (mounted) Navigator.pop(context);
                  }
                },
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  ...entry.value.map((item) {
                    final index = widget.meal.items.indexOf(item);
                    final calories = (item.food.caloriesPer100g * item.quantity) / 100;
                    final proteins = (item.food.proteinsPer100g * item.quantity) / 100;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/images/${item.food.image}'),
                          radius: 25,
                        ),
                        title: Text(item.food.name),
                        subtitle: Text('${item.quantity}g — ${calories.toStringAsFixed(0)} kcal • ${proteins.toStringAsFixed(1)}g prot'),
                        onTap: () {
                          _showEditAlimentBottomSheet(context, index);
                        },
                      ),
                    );
                  }).toList(),
                ],
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Calories :', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${widget.meal.totalCalories.toStringAsFixed(0)} kcal'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Protéines :', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${widget.meal.totalProteins.toStringAsFixed(1)} g'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateMealPage(existingMeal: widget.meal),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier ce repas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
