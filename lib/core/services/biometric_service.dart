import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Handles biometric authentication (Face ID / Fingerprint / PIN fallback).
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device supports any secure lock (Biometrics OR PIN/Pattern).
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      debugPrint('BIOMETRIC: device_supported=$supported');
      return supported;
    } catch (e) {
      debugPrint('BIOMETRIC: isAvailable error: $e');
      return false;
    }
  }

  /// Returns the list of enrolled biometric types.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('BIOMETRIC: getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Returns a user-friendly label for the available biometric type.
  static Future<String> getBiometricTypeLabel() async {
    final available = await getAvailableBiometrics();
    if (available.contains(BiometricType.face)) return 'Face ID';
    if (available.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (available.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  /// Attempts biometric authentication.
  /// Returns true if successful, false otherwise.
  /// [errorMessage] is set to a user-friendly string if authentication fails.
  static Future<({bool success, String? error})> authenticateWithResult({
    String reason = 'Authenticate to access Baby Corn',
  }) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN fallback
        ),
      );
      debugPrint('BIOMETRIC: authenticate result=$result');
      return (success: result, error: result ? null : 'Authentication cancelled');
    } on PlatformException catch (e) {
      debugPrint('BIOMETRIC: PlatformException code=${e.code} msg=${e.message}');
      final message = switch (e.code) {
        auth_error.notAvailable =>
          'Biometric authentication is not available on this device.',
        auth_error.notEnrolled =>
          'No biometrics enrolled. Please add a fingerprint in device settings.',
        auth_error.lockedOut =>
          'Too many attempts. Please try again later.',
        auth_error.permanentlyLockedOut =>
          'Biometric locked out permanently. Use your PIN to unlock.',
        auth_error.passcodeNotSet =>
          'Please set a screen lock PIN in your device settings first.',
        _ => 'Authentication failed: ${e.message}',
      };
      return (success: false, error: message);
    } catch (e) {
      debugPrint('BIOMETRIC: unexpected error: $e');
      return (success: false, error: 'An unexpected error occurred.');
    }
  }

  /// Simple authenticate — returns bool only (for backward compat).
  static Future<bool> authenticate({
    String reason = 'Authenticate to access Baby Corn',
  }) async {
    final result = await authenticateWithResult(reason: reason);
    return result.success;
  }
}
