// lib/features/auth/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/repositories/baby_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

      if (!hasBabies) {
        debugPrint('🔍 [Splash] → /onboarding (no babies)');
        if (mounted) context.go('/onboarding');
      } else {
        debugPrint('🔍 [Splash] → /home (babies exist)');
        if (mounted) context.go('/home');
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
