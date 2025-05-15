import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class StravaService {
  static const String clientId = '159613';
  static const String clientSecret = '026a7fe46939ac25716ed745765a32540b7286bb';
  static const String redirectUri = 'com.example.app://strava-callback';
  static const String authEndpoint = 'https://www.strava.com/oauth/authorize';
  static const String tokenEndpoint = 'https://www.strava.com/oauth/token';

  static Future<String?> authenticate() async {
    final url = Uri.parse('$authEndpoint?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&approval_prompt=auto&scope=activity:read');

    final result = await FlutterWebAuth.authenticate(
      url: url.toString(),
      callbackUrlScheme: 'com.example.app',
    );

    final code = Uri.parse(result).queryParameters['code'];
    return code;
  }

  static Future<String?> getAccessToken(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['access_token'];
    } else {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecentActivities(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://www.strava.com/api/v3/athlete/activities?per_page=5'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erreur lors de la récupération des activités');
    }
  }
}