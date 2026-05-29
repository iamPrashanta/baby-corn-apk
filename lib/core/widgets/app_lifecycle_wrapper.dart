// core/widgets/app_lifecycle_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../local_storage/secure_storage_manager.dart';
import '../services/biometric_service.dart';
import '../services/security_service.dart';
import '../../features/records/presentation/providers/active_session_provider.dart';

class AppLifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;
  
  const AppLifecycleWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends ConsumerState<AppLifecycleWrapper> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSecurityFeatures();
  }
  
  Future<void> _initSecurityFeatures() async {
    final screenshotEnabled = await SecureStorageManager.isScreenshotProtectionEnabled();
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background — stop the timer ticker to save battery
      // The session data is persisted in Hive, and currentDuration uses
      // DateTime.now() math, so it stays accurate without ticking.
      ref.read(activeSessionProvider.notifier).pauseTicker();
      
      await SecureStorageManager.updateLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground — restart the timer ticker for UI updates
      ref.read(activeSessionProvider.notifier).resumeTicker();
      
      final hasPin = await SecureStorageManager.hasPin();
      if (hasPin) {
        final isExpired = await SecureStorageManager.isSessionExpired();
        if (isExpired) {
          final isBiometricEnabled = await SecureStorageManager.isBiometricEnabled();
          bool unlocked = false;
          
          if (isBiometricEnabled && await BiometricService.isAvailable()) {
            unlocked = await BiometricService.authenticate();
          }
          
          if (unlocked) {
            await SecureStorageManager.updateLastActiveTime();
          } else {
            if (mounted) GoRouter.of(context).push('/pin_verify');
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
