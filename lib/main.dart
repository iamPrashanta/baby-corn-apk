// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/local_storage/hive_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'core/services/reminder_service.dart';
import 'core/config/app_config.dart';
import 'core/widgets/app_lifecycle_wrapper.dart';
import 'core/widgets/floating_timer_overlay.dart';
import 'core/providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

// Firebase imports — conditionally used based on AppConfig flags
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Silence ALL debug output in production — must be first
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  debugPrint("STEP 1: WidgetsFlutterBinding initialized");

  // Enable edge-to-edge Android UI overlays
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    debugPrint("STEP 2: Initializing Firebase");
    if (AppConfig.enableFirebase) {
      // Use native google-services.json config on Android, avoid placeholder options
      await Firebase.initializeApp();
      debugPrint("STEP 2.5: Firebase initialized, checking AppCheck");
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    }

    debugPrint("STEP 3: Initializing Hive");
    await HiveManager.init();

    debugPrint("STEP 4: Initializing ReminderService");
    await ReminderService.init();

    debugPrint("STEP 5: Running App");
    runApp(
      const ProviderScope(
        child: BabyCornApp(),
      ),
    );
  } catch (e, st) {
    debugPrint("STARTUP ERROR: $e");
    debugPrint(st.toString());
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  "Startup Error:\n\n$e\n\n$st",
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class BabyCornApp extends ConsumerWidget {
  const BabyCornApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return AppLifecycleWrapper(
      child: MaterialApp.router(
        title: 'Baby Corn',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        builder: (context, child) {
          // Global overlay layer: floating timer appears on ALL screens
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
              children: [
                if (child != null) Positioned.fill(child: child),
                // Floating timer overlay — visible on all routes when active
                const FloatingTimerOverlay(),
              ],
            ),
          );
        },
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
