import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({Key? key}) : super(key: key);

  final List<Map<String, String>> faqData = const [
    {
      'question': 'Comment ajouter un repas ?',
      'answer': 'Va dans l’onglet "Nutrition", puis clique sur le bouton "+" pour ajouter un nouveau repas.'
    },
    {
      'question': 'Comment modifier mes objectifs ?',
      'answer': 'Dans les paramètres, clique sur "Objectifs nutritionnels" pour ajuster tes calories et protéines.'
    },
    {
      'question': 'Puis-je utiliser l’app sans compte ?',
      'answer': 'Oui, un mode invité est disponible. Cependant, certaines données peuvent ne pas être sauvegardées.'
    },
    {
      'question': 'Est-ce que mes données sont enregistrées ?',
      'answer': 'Oui, elles sont stockées localement sur ton appareil (ou dans le cloud si tu es connecté).'
    },
    {
      'question': 'Comment contacter le développeur ?',
      'answer': 'Dans les paramètres, clique sur "Contacter le support" pour envoyer un message.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqData.length,
        itemBuilder: (context, index) {
          final item = faqData[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(item['question']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(item['answer']!, style: const TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
