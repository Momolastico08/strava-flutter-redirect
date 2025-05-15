import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanFoodPage extends StatefulWidget {
  const ScanFoodPage({Key? key}) : super(key: key);

  @override
  State<ScanFoodPage> createState() => _ScanFoodPageState();
}

class _ScanFoodPageState extends State<ScanFoodPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  String _rawText = '';
  bool _isProcessing = false;

  final List<String> calorieKeywords = ['kcal', 'énergie'];
  final List<String> proteinKeywords = ['protéines', 'proteine', 'protein', 'prot'];
  final List<String> carbKeywords = ['glucides', 'carbohydrate', 'sucres'];
  final List<String> fatKeywords = ['lipides', 'graisses', 'fat'];

  @override
  void dispose() {
    _textRecognizer.close();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _selectImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Prendre une photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choisir depuis la galerie', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _rawText = '';
      });
      await _recognizeText();
    }
  }

  Future<void> _recognizeText() async {
    if (_image == null) return;

    setState(() => _isProcessing = true);

    final inputImage = InputImage.fromFile(_image!);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final text = _sanitizeText(recognizedText.text);

    setState(() {
      _rawText = text;
      _parseNutritionInfo(text);
      _isProcessing = false;
    });
  }

  String _sanitizeText(String text) => text.toLowerCase().replaceAll('énergie', 'kcal');

  void _parseNutritionInfo(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      if (calorieKeywords.any(line.contains)) {
        _caloriesController.text = _extractNumber(line)?.toStringAsFixed(0) ?? '';
      }
      if (proteinKeywords.any(line.contains)) {
        _proteinsController.text = _extractNumber(line)?.toStringAsFixed(1) ?? '';
      }
      if (carbKeywords.any(line.contains)) {
        _carbsController.text = _extractNumber(line)?.toStringAsFixed(1) ?? '';
      }
      if (fatKeywords.any(line.contains)) {
        _fatsController.text = _extractNumber(line)?.toStringAsFixed(1) ?? '';
      }
    }
  }

  double? _extractNumber(String line) {
    final regex = RegExp(r'(\d+([.,]\d+)?)');
    final match = regex.firstMatch(line);
    return match != null ? double.tryParse(match.group(0)!.replaceAll(',', '.')) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Scan Étiquette',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectImageSource,
                          icon: const Icon(Icons.image_search),
                          label: const Text('Sélectionner une image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isProcessing) const Center(child: CircularProgressIndicator()),
                        if (_image != null && !_isProcessing)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!, height: 200),
                          ),
                        if (_rawText.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('📝 Texte détecté :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_rawText, style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildNutritionForm(),
                        const SizedBox(height: 30),
                        if (_caloriesController.text.isNotEmpty || _proteinsController.text.isNotEmpty)
                          _buildSummaryCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_caloriesController, 'Calories (kcal)'),
        _buildTextField(_proteinsController, 'Protéines (g)'),
        _buildTextField(_carbsController, 'Glucides (g)'),
        _buildTextField(_fatsController, 'Lipides (g)'),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, {
              'calories': double.tryParse(_caloriesController.text),
              'proteins': double.tryParse(_proteinsController.text),
              'carbs': double.tryParse(_carbsController.text),
              'fats': double.tryParse(_fatsController.text),
            });
          },
          icon: const Icon(Icons.check),
          label: const Text('Ajouter cet aliment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧾 Résumé nutritionnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          _buildSummaryRow('Calories', _caloriesController.text, 'kcal'),
          _buildSummaryRow('Protéines', _proteinsController.text, 'g'),
          _buildSummaryRow('Glucides', _carbsController.text, 'g'),
          _buildSummaryRow('Lipides', _fatsController.text, 'g'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('$value $unit', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
