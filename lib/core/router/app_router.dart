// core/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens will be imported here
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/pin_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';

import '../../features/dashboard/presentation/screens/main_scaffold.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/records/presentation/screens/feeding_entry_screen.dart';
import '../../features/records/presentation/screens/sleep_entry_screen.dart';
import '../../features/records/presentation/screens/diaper_entry_screen.dart';
import '../../features/records/presentation/screens/bath_entry_screen.dart';
import '../../features/settings/presentation/screens/manage_babies_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/pin_setup',
        builder: (context, state) => const PinScreen(isSetup: true),
      ),
      GoRoute(
        path: '/pin_verify',
        builder: (context, state) => const PinScreen(isSetup: false),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          final isAdding = state.uri.queryParameters['add'] == 'true';
          return OnboardingScreen(isAddingBaby: isAdding);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/entry/feeding',
        builder: (context, state) => const FeedingEntryScreen(),
      ),
      GoRoute(
        path: '/entry/sleep',
        builder: (context, state) => const SleepEntryScreen(),
      ),
      GoRoute(
        path: '/entry/diaper',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return DiaperEntryScreen(initialStatus: status);
        },
      ),
      GoRoute(
        path: '/entry/bath',
        builder: (context, state) => const BathEntryScreen(),
      ),
      GoRoute(
        path: '/manage_babies',
        builder: (context, state) => const ManageBabiesScreen(),
      ),
    ],
  );
});
