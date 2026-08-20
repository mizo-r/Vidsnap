import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/app.dart';
import 'package:vidsnap/core/services/clipboard_monitor_service.dart';
import 'package:vidsnap/core/services/notification_service.dart';
import 'package:vidsnap/data/repositories/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation (download manager UX is portrait-first).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Init Hive + register adapters.
  await initStorage();

  // Init notifications.
  final notif = NotificationService();
  await notif.init();
  await notif.requestPermissions();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notif),
      ],
      child: const VidSnapApp(),
    ),
  );
}
