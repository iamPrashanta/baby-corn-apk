// lib/core/widgets/app_lifecycle_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_storage/secure_storage_manager.dart';
import '../services/security_service.dart';
import '../../features/records/presentation/providers/active_session_provider.dart';
import '../router/app_router.dart';
import '../../features/auth/data/repositories/baby_repository.dart';

class AppLifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleWrapper> createState() =>
      _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends ConsumerState<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSecurityFeatures();
    _hasNavigated = false;
  }

  Future<void> _initSecurityFeatures() async {
    final screenshotEnabled =
        await SecureStorageManager.isScreenshotProtectionEnabled();
    if (screenshotEnabled) {
      await SecurityService.enableScreenshotProtection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background — reset navigation guard and pause ticker
      _hasNavigated = false;
      ref.read(activeSessionProvider.notifier).pauseTicker();
      await SecureStorageManager.updateLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground — restart the timer ticker for UI updates
      ref.read(activeSessionProvider.notifier).resumeTicker();

      // Skip lock check if already on the PIN verify screen or splash/auth
      final router = ref.read(routerProvider);
      final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();
      if (currentLocation == '/pin_verify' ||
          currentLocation == '/' ||
          currentLocation == '/auth' ||
          currentLocation == '/language') {
        return;
      }

      final hasBabies = ref.read(babyRepositoryProvider).getBabies().isNotEmpty;

      if (hasBabies) {
        final isExpired = await SecureStorageManager.isSessionExpired();
        if (isExpired) {
          // Navigate to pin_verify — let PinScreen handle biometric prompt
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            router.go('/pin_verify');
          }
        } else {
          await SecureStorageManager.updateLastActiveTime();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
