import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_service.dart';
import 'notification_service.dart';
import 'contact_page.dart';
import 'faq_page.dart';
import 'sources_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  bool _hydrationReminder = false;
  TimeOfDay _hydrationReminderTime = const TimeOfDay(hour: 14, minute: 0);
  String _themeMode = 'system';
  String _accentColor = 'orange';
  bool _isFullscreen = true;
  bool _advancedAnalysis = true;
  String _installDate = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _hydrationReminder = prefs.getBool('hydrationReminder') ?? false;
      final hour = prefs.getInt('notifHour') ?? 20;
      final minute = prefs.getInt('notifMinute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);

      final hydHour = prefs.getInt('hydrationHour') ?? 14;
      final hydMinute = prefs.getInt('hydrationMinute') ?? 0;
      _hydrationReminderTime = TimeOfDay(hour: hydHour, minute: hydMinute);

      _themeMode = prefs.getString('themeMode') ?? 'system';
      _accentColor = prefs.getString('accentColor') ?? 'orange';
      _isFullscreen = prefs.getBool('fullscreen') ?? true;
      _advancedAnalysis = prefs.getBool('advancedAnalysis') ?? true;

      final installTimestamp = prefs.getInt('installDate') ??
          DateTime.now().millisecondsSinceEpoch;
      prefs.setInt('installDate', installTimestamp);
      final date = DateTime.fromMillisecondsSinceEpoch(installTimestamp);
      _installDate = '${date.day}/${date.month}/${date.year}';
    });

    _applyFullscreen();
  }

  Future<void> _applyFullscreen() async {
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _toggleFullscreen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fullscreen', value);
    setState(() => _isFullscreen = value);
    _applyFullscreen();
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() => _notificationsEnabled = value);
    if (value) {
      await NotificationService.scheduleDailyNotification();
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

  Future<void> _selectNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notifHour', picked.hour);
      await prefs.setInt('notifMinute', picked.minute);
      setState(() => _notificationTime = picked);
      await NotificationService.scheduleDailyNotification();
    }
  }

  Future<void> _selectHydrationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hydrationReminderTime,
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hydrationHour', picked.hour);
      await prefs.setInt('hydrationMinute', picked.minute);
      setState(() => _hydrationReminderTime = picked);
    }
  }

  Future<void> _toggleAdvancedAnalysis(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advancedAnalysis', value);
    setState(() => _advancedAnalysis = value);
  }

  Future<void> _chooseTheme() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Choisir un thème', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildThemeOption('Clair', 'light'),
          _buildThemeOption('Sombre', 'dark'),
          _buildThemeOption('Automatique', 'auto'),
          _buildThemeOption('Système', 'system'),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _themeMode,
      onChanged: (val) async {
        await ThemeService().setThemeMode(val!);
        setState(() => _themeMode = val);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _chooseAccentColor() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Couleur principale', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _buildAccentChip('Orange', 'orange', Colors.orange),
                _buildAccentChip('Bleu', 'blue', Colors.blue),
                _buildAccentChip('Violet', 'purple', Colors.purple),
                _buildAccentChip('Vert', 'green', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentChip(String label, String value, Color color) {
    return ChoiceChip(
      label: Text(label),
      selected: _accentColor == value,
      selectedColor: color.withOpacity(0.7),
      backgroundColor: Colors.grey.shade200,
      labelStyle: const TextStyle(color: Colors.black),
      avatar: CircleAvatar(backgroundColor: color),
      onSelected: (selected) async {
        HapticFeedback.lightImpact();
        await ThemeService().setThemeColor(value);
        setState(() => _accentColor = value);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préférences réinitialisées')));
    setState(() => _loadSettings());
  }

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _shareApp() {
    Share.share("Découvre l'app Muscu Tracker ! 💪\nhttps://monapp.com");
  }

  void _exportData() {
    // Placeholder fonction export (à améliorer plus tard)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonction d'export en cours de développement 📦")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionTitle('Notifications'),
                  _buildGlassCard([
                    SwitchListTile(
                      title: const Text('Activer les notifications', style: TextStyle(color: Colors.white)),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      secondary: const Icon(Icons.notifications_active, color: Colors.white),
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.white70),
                      title: const Text('Heure quotidienne', style: TextStyle(color: Colors.white)),
                      subtitle: Text(_notificationTime.format(context), style: const TextStyle(color: Colors.white70)),
                      onTap: _selectNotificationTime,
                    ),
                    SwitchListTile(
                      title: const Text('Rappel hydratation', style: TextStyle(color: Colors.white)),
                      value: _hydrationReminder,
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hydrationReminder', val);
                        setState(() => _hydrationReminder = val);
                      },
                      secondary: const Icon(Icons.water_drop_outlined, color: Colors.white),
                    ),
                    if (_hydrationReminder)
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.white70),
                        title: const Text("Heure du rappel d'hydratation", style: TextStyle(color: Colors.white)),
                        subtitle: Text(_hydrationReminderTime.format(context), style: const TextStyle(color: Colors.white70)),
                        onTap: _selectHydrationTime,
                      ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Apparence & fonctions'),
                  _buildGlassCard([
                    SwitchListTile(
                      title: const Text('Mode plein écran', style: TextStyle(color: Colors.white)),
                      value: _isFullscreen,
                      onChanged: _toggleFullscreen,
                      secondary: const Icon(Icons.fullscreen, color: Colors.white),
                    ),
                    SwitchListTile(
                      title: const Text('Analyse avancée activée', style: TextStyle(color: Colors.white)),
                      value: _advancedAnalysis,
                      onChanged: _toggleAdvancedAnalysis,
                      secondary: const Icon(Icons.analytics, color: Colors.white),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens, color: Colors.white70),
                      title: const Text("Thème de l'application", style: TextStyle(color: Colors.white)),
                      subtitle: Text(_themeMode.capitalize(), style: const TextStyle(color: Colors.white70)),
                      onTap: _chooseTheme,
                    ),
                    ListTile(
                      leading: const Icon(Icons.palette, color: Colors.white70),
                      title: const Text('Couleur principale', style: TextStyle(color: Colors.white)),
                      subtitle: Text(_accentColor.capitalize(), style: const TextStyle(color: Colors.white70)),
                      onTap: _chooseAccentColor,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Autres'),
                  _buildGlassCard([
                    ListTile(
                      leading: const Icon(Icons.science_outlined, color: Colors.white70),
                      title: const Text('Sources scientifiques', style: TextStyle(color: Colors.white)),
                      subtitle: const Text("Études utilisées dans l'application", style: TextStyle(color: Colors.white60)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourcesPage())),
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_file, color: Colors.white70),
                      title: const Text("Exporter mes données", style: TextStyle(color: Colors.white)),
                      onTap: _exportData,
                    ),
                    ListTile(
                      leading: const Icon(Icons.share, color: Colors.white70),
                      title: const Text("Partager l'application", style: TextStyle(color: Colors.white)),
                      onTap: _shareApp,
                    ),
                    ListTile(
                      leading: const Icon(Icons.mail_outline, color: Colors.white70),
                      title: const Text('Contacter le support', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage())),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: Colors.white70),
                      title: const Text('Réinitialiser les préférences', style: TextStyle(color: Colors.white)),
                      onTap: _resetPreferences,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white70),
                      title: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
                      onTap: _logout,
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.white70),
                      title: const Text('À propos', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Installé le $_installDate\nMuscu Tracker • Version 1.0.0',
                          style: const TextStyle(color: Colors.white60)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
