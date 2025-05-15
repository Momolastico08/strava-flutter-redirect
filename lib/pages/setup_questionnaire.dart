import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/main_controller.dart';

class SetupQuestionnairePage extends StatefulWidget {
  const SetupQuestionnairePage({Key? key}) : super(key: key);

  @override
  State<SetupQuestionnairePage> createState() => _SetupQuestionnairePageState();
}

class _SetupQuestionnairePageState extends State<SetupQuestionnairePage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? _gender;
  int? _age;
  int? _height;
  int? _weight;
  String? _goal;

  final List<String> genders = ['Homme', 'Femme', 'Autre'];
  final List<String> goals = ['Prise de masse', 'Perte de poids', 'Maintien'];

  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  final List<String> _illustrations = [
    'assets/images/gender.png',
    'assets/images/age.png',
    'assets/images/height.png',
    'assets/images/weight.png',
    'assets/images/goal.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gender = prefs.getString('gender');
      _age = prefs.getInt('age');
      _height = prefs.getInt('height');
      _weight = prefs.getInt('weight');
      _goal = prefs.getString('goal');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.deepOrangeAccent,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: 5,
                itemBuilder: (context, index) => _buildSlide(context, index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: Icon(
                    _currentPage == 4 ? Icons.check_circle_outline : Icons.arrow_forward_ios),
                label: Text(
                  _currentPage == 4 ? 'Terminer' : 'Suivant',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 100));
                  final currentForm = _formKeys[_currentPage];
                  if (currentForm.currentState!.validate()) {
                    currentForm.currentState!.save();
                    if (_currentPage < 4) {
                      setState(() => _currentPage++);
                      _pageController.animateToPage(
                        _currentPage,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      await _saveProfile();
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.deepOrange.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, int index) {
    final titles = [
      'Quel est ton genre ?',
      "Quel est ton âge ?",
      "Quelle est ta taille ?",
      "Quel est ton poids ?",
      "Quel est ton objectif ?",
    ];

    final descriptions = [
      "Nous utilisons ton genre pour mieux adapter les recommandations.",
      "Cela nous aide à mieux comprendre ton métabolisme.",
      "Ta taille permet d'estimer ton IMC.",
      "Ton poids est utilisé pour le calcul des besoins journaliers.",
      "Ton objectif détermine le plan nutritionnel recommandé.",
    ];

    final formKey = _formKeys[index];

    Widget input;
    switch (index) {
      case 0:
        input = _buildDropdown(
          genders,
          _gender,
              (val) => setState(() => _gender = val),
              (val) => _gender = val,
        );
        break;
      case 1:
        input = _buildNumberField((val) => _age = int.tryParse(val ?? ''), hint: 'Ex: 25');
        break;
      case 2:
        input = _buildNumberField((val) => _height = int.tryParse(val ?? ''), hint: 'En cm');
        break;
      case 3:
        input = _buildNumberField((val) => _weight = int.tryParse(val ?? ''), hint: 'En kg');
        break;
      case 4:
        input = _buildDropdown(
          goals,
          _goal,
              (val) => setState(() => _goal = val),
              (val) => _goal = val,
        );
        break;
      default:
        input = const SizedBox();
    }

    return Form(
      key: formKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_illustrations.length > index)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(_illustrations[index], height: 160),
                  ),
                Text(
                  titles[index],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  descriptions[index],
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                input,
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    filled: true,
    fillColor: Colors.grey.shade100,
  );

  Widget _buildDropdown(List<String> options, String? value, Function(String?) onChanged,
      Function(String?) onSaved) {
    return DropdownButtonFormField<String>(
      value: value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration('Sélectionner'),
      items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      onSaved: onSaved,
      validator: (value) => value == null ? 'Veuillez faire un choix' : null,
    );
  }

  Widget _buildNumberField(Function(String?) onSaved, {required String hint}) {
    return TextFormField(
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(hint),
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer une valeur';
        final parsed = int.tryParse(value);
        if (parsed == null) return 'Nombre invalide';
        if (parsed < 10 || parsed > 250) return 'Valeur hors limite';
        return null;
      },
    );
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', _gender!);
    await prefs.setInt('age', _age!);
    await prefs.setInt('height', _height!);
    await prefs.setInt('weight', _weight!);
    await prefs.setString('goal', _goal!);
    await prefs.setBool('profileCompleted', true);

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => MainController(),
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }
}
