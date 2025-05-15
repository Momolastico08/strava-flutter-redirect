import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SourcesPage extends StatelessWidget {
  const SourcesPage({super.key});

  final List<Map<String, String>> sources = const [
    {
      'title': 'Schoenfeld et al. (2018)',
      'desc': 'Quantité optimale de protéines par repas pour l’hypertrophie musculaire',
      'url': 'https://pubmed.ncbi.nlm.nih.gov/29497353/',
    },
    {
      'title': 'Schoenfeld, B.J. (2010)',
      'desc': 'Volume d’entraînement et croissance musculaire',
      'url': 'https://pubmed.ncbi.nlm.nih.gov/20847704/',
    },
    {
      'title': 'EFSA (2010)',
      'desc': 'Apports recommandés en eau selon le poids corporel',
      'url': 'https://efsa.onlinelibrary.wiley.com/doi/10.2903/j.efsa.2010.1459',
    },
    {
      'title': 'Mifflin-St Jeor Equation',
      'desc': 'Calcul du métabolisme de base recommandé par l’OMS',
      'url': 'https://pubmed.ncbi.nlm.nih.gov/8773653/',
    },
  ];

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Impossible d’ouvrir : $url")));
    }
  }

  void _copyAllSources(BuildContext context) {
    final text = sources.map((s) => '${s['title']}: ${s['url']}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Liens copiés dans le presse-papiers.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources scientifiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copier toutes les sources',
            onPressed: () => _copyAllSources(context),
          )
        ],
      ),
      backgroundColor: const Color(0xFF0f2027),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sources.length,
        itemBuilder: (context, index) {
          final source = sources[index];
          return Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text(source['title']!, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              subtitle: Text(source['desc']!, style: const TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.open_in_new, color: Colors.white54),
              onTap: () => _launchURL(context, source['url']!),
            ),
          );
        },
      ),
    );
  }
}
