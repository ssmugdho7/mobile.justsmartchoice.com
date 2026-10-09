import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupPermissions {
  StartupPermissions({
    required this.hasCompleted,
    required this.markCompleted,
    required this.request,
  });
  final Future<bool> Function() hasCompleted;
  final Future<void> Function() markCompleted;
  final Future<void> Function(Permission) request;

  Future<void> run() async {
    if (await hasCompleted()) return;
    // Denial must not prevent Home from loading or cause repeated startup prompts.
    for (final permission in [
      Permission.microphone,
      Permission.notification,
      Permission.camera,
    ]) {
      await request(permission);
    }
    await markCompleted();
  }

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final preferences = SharedPreferencesAsync();
      await StartupPermissions(
        hasCompleted: () async =>
            await preferences.getBool('startupPermissionsCompleted') ?? false,
        markCompleted: () =>
            preferences.setBool('startupPermissionsCompleted', true),
        request: (permission) async {
          final status = await permission.status;
          if (!status.isGranted && !status.isPermanentlyDenied) {
            await permission.request();
          }
        },
      ).run();
    } catch (_) {
      // OS/plugin failures never lock the user out of their website or CRM.
    }
  }
}
