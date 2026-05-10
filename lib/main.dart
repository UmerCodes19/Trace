import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/services/notification_service.dart';


import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/local_settings_service.dart';
import 'data/services/offline/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Cloud-based architecture - no local DB init needed

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Initialize Notifications
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Local Settings
  final prefs = await SharedPreferences.getInstance();

  // Initialize Offline Sync Manager
  try {
    await SyncManager.instance.initialize();
    debugPrint('Offline Sync Manager initialized successfully');
  } catch (e) {
    debugPrint('Offline Sync Manager initialization error: $e');
  }


  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // GLOBAL FAIL-SAFE: Prevent the UI from ever showing yellow/black tapes or red crash screens globally.
  // This catches unforeseen layout crashes and replaces them with a silent container so users never see visual breakage.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('🔥 [SILENCED UI ERROR] -> ${details.exception}');
    // Safely render nothing instead of breaking the visuals for the user
    return const SizedBox.shrink(); 
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LostFoundApp(),
    ),
  );
}

class LostFoundApp extends ConsumerWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(themeProvider);
    final accentInt = ref.watch(accentColorProvider);
    final accent = Color(accentInt);

    return MaterialApp.router(
      title: 'Trace - Bahria University',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
