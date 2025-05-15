// lib/pages/permission_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestNotificationPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final sdkInt = (await Permission.notification.status).isGranted;

      if (!sdkInt) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          debugPrint('Notification permission granted');
        } else if (status.isDenied) {
          debugPrint('Notification permission denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications refusées. Activez-les dans les paramètres.')),
          );
        } else if (status.isPermanentlyDenied) {
          debugPrint('Notification permission permanently denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications bloquées. Veuillez activer manuellement dans les paramètres.')),
          );
        }
      }
    }
  }
}
