// lib/features/auth/presentation/screens/pin_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/local_storage/secure_storage_manager.dart';
import '../../data/repositories/baby_repository.dart';

class PinScreen extends ConsumerStatefulWidget {
  // This screen is now only used to trigger biometric authentication.
  // The `isSetup` flag is kept for compatibility but has no effect.
  final bool isSetup;
  const PinScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  bool _isLoading = true;
  String _error = '';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Delay slightly to ensure the screen is fully mounted before
    // showing the system biometric dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometric();
    });
  }

  void _navigateHome() {
    if (!mounted) return;
    SecureStorageManager.updateLastActiveTime();
    final repo = ref.read(babyRepositoryProvider);
    final hasBabies = repo.getBabies().isNotEmpty;
    context.go(hasBabies ? '/home' : '/onboarding');
  }

  Future<void> _attemptBiometric() async {
    // Guard against re-entrancy (lifecycle events can cause double calls)
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final isAvailable = await BiometricService.isAvailable();
    if (!mounted) return;

    if (isAvailable) {
      final result = await BiometricService.authenticateWithResult(
        reason: 'Unlock Baby Corn with your fingerprint or face',
      );
      if (!mounted) return;
      _isAuthenticating = false;

      if (result.success) {
        _navigateHome();
        return;
      } else if (result.error != null &&
          result.error != 'Authentication cancelled') {
        setState(() {
          _error = result.error!;
          _isLoading = false;
        });
        return;
      } else {
        // User cancelled — show retry UI, don't loop
        setState(() {
          _error = 'Authentication cancelled. Tap Retry to try again.';
          _isLoading = false;
        });
        return;
      }
    }

    _isAuthenticating = false;

    // Biometric not available — let user in directly
    // (Device has no biometric/PIN set up, can't lock them out)
    _navigateHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: Colors.orange, size: 56),
                    const SizedBox(height: 16),
                    Text(_error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _attemptBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

