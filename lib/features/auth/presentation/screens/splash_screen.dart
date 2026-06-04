// lib/features/auth/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/repositories/baby_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/tokens/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if app was launched from a notification alarm
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

      final didNotificationLaunchApp =
          notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;
      final payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;

      if (!mounted) return;

      if (didNotificationLaunchApp &&
          payload != null &&
          payload.startsWith('alarm|')) {
        debugPrint('🔔 [Splash] Launched from alarm notification');
        context.go('/alarm', extra: payload);
        return;
      }

      // --- Check language selection ---
      final prefs = await SharedPreferences.getInstance();
      // Language selection removed
      final hasSelectedLanguage =
          prefs.getBool('has_selected_language') ?? false;
      debugPrint('🔍 [Splash] has_selected_language=$hasSelectedLanguage');

      if (!hasSelectedLanguage) {
        debugPrint('🔍 [Splash] → /language (language not selected yet)');
        if (mounted) context.go('/language');
        return;
      }

      // --- Read baby list (migration already complete by this point) ---
      final babies = ref.read(babyRepositoryProvider).getBabies();
      final hasBabies = babies.isNotEmpty;
      final activeBabyId =
          ref.read(babyRepositoryProvider).getActiveBabyId();
      debugPrint('🔍 [Splash] babies.count=${babies.length}, hasBabies=$hasBabies, activeBabyId=$activeBabyId');

      final isOfflineMode = prefs.getBool('is_offline_mode') ?? false;

      if (AppConfig.enableFirebaseAuth && !isOfflineMode) {
        // FIX #1: Await full Firebase auth state restoration before reading currentUser.
        // FirebaseAuth.instance.currentUser is synchronous and may be null on cold
        // start even for signed-in users — the SDK hasn't finished restoring the
        // persisted token yet. authStateChanges().first waits until it is ready.
        debugPrint('🔍 [Splash] Awaiting Firebase auth state...');
        final currentUser = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('⚠️ [Splash] Firebase auth state timeout — treating as signed out');
                return null;
              },
            );

        debugPrint('🔍 [Splash] currentUser.uid=${currentUser?.uid}, currentUser.email=${currentUser?.email}');

        if (!mounted) return;

        if (currentUser != null) {
          // ✅ Returning user: Firebase session confirmed
          if (!mounted) return;
          final route = hasBabies ? '/home' : '/onboarding';
          debugPrint('🔍 [Splash] → $route');
          context.go(route);
        } else {
          // Not signed in → show Google sign-in screen
          debugPrint('🔍 [Splash] → /auth (no Firebase session)');
          context.go('/auth');
        }
      } else {
        // Local-First Offline mode — no Firebase auth required
        debugPrint("🔍 Splash babies count = ${babies.length}");
        debugPrint("🔍 Splash active baby = $activeBabyId");
        debugPrint("🔍 Splash route => ${hasBabies ? '/home' : '/onboarding'}");

        if (!hasBabies) {
          debugPrint('🔍 [Splash] → /onboarding (offline, no babies)');
          if (mounted) context.go('/onboarding');
        } else {
          debugPrint('🔍 [Splash] → /home (offline)');
          if (mounted) context.go('/home');
        }
      }
    } catch (e, st) {
      debugPrint('🔴 [Splash] Routing error: $e\n$st');
      // Safe fallback — never loop back to /auth
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRect(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  'assets/animations/378464813.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().fade(duration: 800.ms).scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOutBack,
                duration: 800.ms),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
