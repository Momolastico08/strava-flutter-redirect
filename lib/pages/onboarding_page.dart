// lib/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'setup_questionnaire.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<List<Color>> _gradients = [
    [Colors.deepPurple, Colors.purpleAccent],
    [Colors.deepOrange, Colors.orangeAccent],
    [Colors.teal, Colors.cyan],
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildPage(
        animation: 'assets/animations/fitness.json',
        title: 'Bienvenue',
        subtitle: 'Découvrez votre compagnon MuscuTracker',
        helper: 'Un outil moderne pour suivre vos performances.',
      ),
      _buildPage(
        animation: 'assets/animations/nutrition.json',
        title: 'Nutrition',
        subtitle: "Suivez vos repas en un clin d'œil",
        helper: 'Ajoutez facilement des aliments et suivez vos macros.',
      ),
      _buildPage(
        animation: 'assets/animations/history.json',
        title: 'Historique',
        subtitle: 'Consultez vos progrès jour après jour',
        helper: 'Visualisez vos entraînements sur la durée.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: _completeOnboarding,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[_currentPage],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Text(
              ['Bienvenue à MuscuTracker!', 'Maîtrisez votre alimentation', 'Suivez votre évolution'][_currentPage],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (_, index) => pages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / pages.length,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomSheet: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: Colors.white.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage != 0)
                ElevatedButton(
                  onPressed: _previousPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _gradients[_currentPage][0],
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Précédent'),
                )
              else
                const Spacer(),
              Row(
                children: List.generate(
                  pages.length,
                      (index) => _buildDot(index == _currentPage),
                ),
              ),
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _gradients[_currentPage][0],
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(_currentPage == 2 ? 'Commencer' : 'Suivant'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required String animation,
    required String title,
    required String subtitle,
    required String helper,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(animation, height: MediaQuery.of(context).size.height * 0.3),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            helper,
            style: const TextStyle(fontSize: 14, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 14 : 8,
      height: isActive ? 14 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    final profileCompleted = prefs.getBool('profileCompleted') ?? false;

    if (profileCompleted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupQuestionnairePage()),
      );
    }
  }
}
