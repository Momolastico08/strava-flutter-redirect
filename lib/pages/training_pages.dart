// lib/pages/training_pages.dart

import 'package:flutter/material.dart';
import 'create_training_session_page.dart';
import '../services/database_helper.dart';
import '../models/session_model.dart';
import 'session_detail_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({Key? key}) : super(key: key);

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  List<Session> sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final allSessions = await DatabaseHelper.instance.getSessions();
    setState(() {
      sessions = allSessions;
      sessions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes Entraînements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTrainingSessionPage()),
                  );
                  _loadSessions();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: sessions.isEmpty
                ? const Center(child: Text('Aucune séance enregistrée', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ListTile(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/session_detail',
                        arguments: session,
                      );
                    },
                    title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${session.exercises.length} exercice(s)'),
                    trailing: Text(
                      '${session.date.day}/${session.date.month}/${session.date.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
