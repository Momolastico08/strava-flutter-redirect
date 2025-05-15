// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/splash.dart';
import 'pages/main_controller.dart';
import 'pages/onboarding_page.dart';
import 'pages/setup_questionnaire.dart';
import 'pages/exercise_list_page.dart';
import 'pages/session_detail_page.dart';
import 'models/session_model.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // MODE PLEIN ÉCRAN
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService(); // Singleton d'apparence
    _themeService.loadTheme();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<Widget> _decideInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final profileCompleted = prefs.getBool('profileCompleted') ?? false;

    if (!seenOnboarding) {
      return const OnboardingPage();
    } else if (!profileCompleted) {
      return const SetupQuestionnairePage();
    } else {
      return const SplashWrapper();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muscu Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: _themeService.themeMode,
      theme: ThemeData(
        primarySwatch: _themeService.primaryColor,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      darkTheme: ThemeData(
        primarySwatch: _themeService.primaryColor,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: FutureBuilder<Widget>(
        future: _decideInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return const Scaffold(
              body: Center(child: Text('Erreur de chargement')),
            );
          }
        },
      ),
      routes: {
        '/exercise_list': (context) => const ExerciseListPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/session_detail') {
          final session = settings.arguments as Session;
          return MaterialPageRoute(
            builder: (context) => SessionDetailPage(session: session),
          );
        }
        return null;
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({Key? key}) : super(key: key);

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with SingleTickerProviderStateMixin {
  bool _splashFinished = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  void _onSplashEnd() {
    _fadeController.forward().then((_) {
      setState(() {
        _splashFinished = true;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const MainController(),
        if (!_splashFinished)
          FadeTransition(
            opacity: ReverseAnimation(_fadeAnimation),
            child: SplashScreen(onVideoEnd: _onSplashEnd),
          ),
      ],
    );
  }
}
