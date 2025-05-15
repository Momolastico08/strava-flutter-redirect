import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/database_helper.dart';
import '../models/strava_activity.dart';


class StravaImportPage extends StatefulWidget {
  const StravaImportPage({super.key});

  @override
  State<StravaImportPage> createState() => _StravaImportPageState();
}

class _StravaImportPageState extends State<StravaImportPage> {
  final String clientId = '159613';
  final String clientSecret = '026a7fe46939ac25716ed745765a32540b7286bb';
  final String redirectUri = 'https://strava-flutter-redirect.onrender.com/strava/callback';
  final String callbackScheme = 'muscutracker';
  final secureStorage = FlutterSecureStorage();

  String? accessToken;
  List<Map<String, dynamic>> activities = [];
  Set<String> importedStravaIds = {};

  @override
  void initState() {
    super.initState();
    _loadImportedActivities();
    _loadSavedToken();
  }

  Future<void> _loadImportedActivities() async {
    final saved = await DatabaseHelper.instance.getStravaActivities();
    setState(() {
      importedStravaIds = saved.map((e) => e.stravaId).toSet();
    });
  }

  Future<void> _loadSavedToken() async {
    final token = await secureStorage.read(key: 'strava_token');
    final refresh = await secureStorage.read(key: 'strava_refresh');
    final expires = await secureStorage.read(key: 'strava_expires');

    if (token != null && refresh != null && expires != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiresAt = int.tryParse(expires);
      if (expiresAt != null && now >= expiresAt) {
        await _refreshToken(refresh);
      } else {
        accessToken = token;
        await _fetchActivities();
      }
    }
  }

  Future<void> _refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );
    final data = json.decode(response.body);
    if (data['access_token'] != null) {
      accessToken = data['access_token'];
      await secureStorage.write(key: 'strava_token', value: data['access_token']);
      await secureStorage.write(key: 'strava_refresh', value: data['refresh_token']);
      await secureStorage.write(key: 'strava_expires', value: data['expires_at'].toString());
      await _fetchActivities();
    }
  }

  Future<void> _connectToStrava() async {
    final authUrl = Uri.https('www.strava.com', '/oauth/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'approval_prompt': 'auto',
      'scope': 'activity:read',
    }).toString();

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        await _exchangeToken(code);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _exchangeToken(String code) async {
    final response = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );
    final data = json.decode(response.body);
    if (data['access_token'] != null) {
      accessToken = data['access_token'];
      await secureStorage.write(key: 'strava_token', value: data['access_token']);
      await secureStorage.write(key: 'strava_refresh', value: data['refresh_token']);
      await secureStorage.write(key: 'strava_expires', value: data['expires_at'].toString());
      await _fetchActivities();
    }
  }

  Future<void> _fetchActivities() async {
    if (accessToken == null) return;
    final response = await http.get(
      Uri.parse('https://www.strava.com/api/v3/athlete/activities'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      final List decoded = json.decode(response.body);
      setState(() {
        activities = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _addToDatabase(Map<String, dynamic> activity) async {
    final model = StravaActivity(
      stravaId: activity['id'].toString(),
      name: activity['name'] ?? 'Activité',
      distance: (activity['distance'] as num).toDouble(),
      duration: (activity['moving_time'] as num).toInt(),
      elevation: (activity['total_elevation_gain'] as num?)?.toDouble() ?? 0.0,
      type: activity['type'] ?? 'Unknown',
      date: DateTime.parse(activity['start_date_local']),
    );
    await DatabaseHelper.instance.insertStravaActivity(model);
    await _loadImportedActivities();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Activité ajoutée.')));
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final stravaId = activity['id'].toString();
    final alreadyImported = importedStravaIds.contains(stravaId);

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity['name'] ?? 'Sans titre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('🏃 ${(activity['distance'] / 1000).toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white)),
            Text('⏱ ${(activity['moving_time'] / 60).toStringAsFixed(0)} min', style: const TextStyle(color: Colors.white)),
            if (activity['total_elevation_gain'] != null)
              Text('📈 ${activity['total_elevation_gain']} m D+', style: const TextStyle(color: Colors.white)),
            Text('📅 ${DateTime.parse(activity['start_date_local']).toLocal().toString().split(" ")[0]}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            if (!alreadyImported)
              ElevatedButton.icon(
                onPressed: () => _addToDatabase(activity),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter à mes entraînements'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              )
            else
              const Text('✅ Déjà ajoutée', style: TextStyle(color: Colors.greenAccent))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer depuis Strava'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _connectToStrava,
            icon: const Icon(Icons.directions_run),
            label: const Text('Connexion Strava'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: activities.isEmpty
                ? const Center(child: Text('Aucune activité trouvée.', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) => _buildActivityCard(activities[index]),
            ),
          )
        ],
      ),
    );
  }
}
