import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'package:RefereeIQ/router/app_routes.dart';
import 'package:RefereeIQ/services/notification_service.dart';
import 'package:RefereeIQ/services/connectivity_service.dart';
import 'package:RefereeIQ/theme.dart';

/// Global theme notifier — read/written by SettingsScreen.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env isn't bundled in production; ignore if missing.
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route all Flutter framework errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Keep Firestore cache warm for offline law lookup
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  FirebaseMessaging.onBackgroundMessage(NotificationService.firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  await ConnectivityService.instance.init();

  // Restore persisted theme preference.
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = ThemeMode.values[prefs.getInt('theme_mode') ?? 0];

  runApp(const RefereeIQApp());
}

class RefereeIQApp extends StatelessWidget {
  const RefereeIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RefereeIQ',
        theme: RefereeIQTheme.lightTheme,
        darkTheme: RefereeIQTheme.darkTheme,
        themeMode: mode,
        initialRoute: '/',
        routes: AppRoutes.routes,
      ),
    );
  }
}
