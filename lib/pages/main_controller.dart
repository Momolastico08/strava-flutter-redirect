import 'dart:ui';
import 'package:flutter/material.dart';
import 'home.dart';
import 'nutrition_page.dart';
import 'training_pages.dart';
import 'workout_history_page.dart';

class MainController extends StatefulWidget {
  const MainController({Key? key}) : super(key: key);

  @override
  State<MainController> createState() => _MainControllerState();
}

class _MainControllerState extends State<MainController> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    NutritionPage(),
    TrainingPage(),
    WorkoutHistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: const Border(
                top: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.orangeAccent,
              unselectedItemColor: Colors.white70,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
                BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutrition'),
                BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Entraînements'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Historique'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
