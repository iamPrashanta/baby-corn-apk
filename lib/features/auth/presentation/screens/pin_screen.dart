// lib/features/auth/presentation/screens/pin_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/biometric_service.dart';

class PinScreen extends StatefulWidget {
  // This screen is now only used to trigger biometric authentication.
  // The `isSetup` flag is kept for compatibility but has no effect.
  final bool isSetup;
  const PinScreen({super.key, this.isSetup = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _attemptBiometric();
  }

  Future<void> _attemptBiometric() async {
    final isAvailable = await BiometricService.isAvailable();
    if (!mounted) return;
    if (isAvailable) {
      final result = await BiometricService.authenticateWithResult(
        reason: 'Unlock Baby Corn with your fingerprint or face',
      );
      if (result.success) {
        // Successful authentication – go to home.
        if (mounted) context.go('/home');
        return;
      } else if (result.error != null &&
          result.error != 'Authentication cancelled') {
        setState(() {
          _error = result.error!;
          _isLoading = false;
        });
        return;
      }
    }
    // Biometric not available or failed.
    setState(() {
      _error = isAvailable
          ? 'Biometric authentication failed.'
          : 'Biometric authentication not available on this device.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Unlock')), // Simple title, can be styled later.
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _attemptBiometric,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
