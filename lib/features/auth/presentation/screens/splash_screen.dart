// features/auth/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/local_storage/secure_storage_manager.dart';
import '../../data/repositories/baby_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final hasSelectedLanguage = prefs.getBool('has_selected_language') ?? false;

      final hasPin = await SecureStorageManager.hasPin();
      final isOnboarded = ref.read(babyRepositoryProvider).isOnboardingComplete();

      if (!mounted) return;

      if (!hasSelectedLanguage) {
        context.go('/language');
        return;
      }

      if (AppConfig.enableFirebaseAuth) {
        if (!hasPin) {
          context.go('/auth');
        } else {
          final isExpired = await SecureStorageManager.isSessionExpired();
          if (!mounted) return;
          if (isExpired) {
            context.go('/pin_verify');
          } else {
            await SecureStorageManager.updateLastActiveTime();
            if (isOnboarded) {
              context.go('/home');
            } else {
              context.go('/onboarding');
            }
          }
        }
      } else {
        // Local-First Offline Logic - NO PIN required
        if (!isOnboarded) {
          context.go('/onboarding');
        } else {
          // Update last active time for consistency, though session doesn't expire without PIN
          await SecureStorageManager.updateLastActiveTime();
          context.go('/home');
        }
      }
    } catch (e) {
      // If anything fails during startup routing, go to auth as a safe fallback
      debugPrint('SplashScreen routing error: $e');
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
            ).animate()
             .fade(duration: 800.ms)
             .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 800.ms),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFFFFB2A6)),
          ],
        ),
      ),
    );
  }
}
