// core/local_storage/secure_storage_manager.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static const _storage = FlutterSecureStorage();
  
  static const String _pinKey = 'user_pin';
  static const String _sessionTimeoutKey = 'session_timeout';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _pinFailedAttemptsKey = 'pin_failed_attempts';
  static const String _pinLockoutUntilKey = 'pin_lockout_until';
  
  // OTP Abuse Prevention Keys
  static const String _otpAttemptsKey = 'otp_attempts_timestamps';
  static const String _otpLockoutUntilKey = 'otp_lockout_until';
  // Security & Privacy Keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _screenshotProtectionKey = 'screenshot_protection';

  // PIN Management
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }
  
  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }
  
  static Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }
  
  // PIN Brute Force Protection
  static Future<int> getPinFailedAttempts() async {
    final count = await _storage.read(key: _pinFailedAttemptsKey);
    return int.tryParse(count ?? '0') ?? 0;
  }
  
  static Future<void> incrementPinFailedAttempts() async {
    final count = await getPinFailedAttempts();
    await _storage.write(key: _pinFailedAttemptsKey, value: (count + 1).toString());
  }
  
  static Future<void> resetPinFailedAttempts() async {
    await _storage.delete(key: _pinFailedAttemptsKey);
    await _storage.delete(key: _pinLockoutUntilKey);
  }
  
  static Future<void> setPinLockoutUntil(DateTime until) async {
    await _storage.write(key: _pinLockoutUntilKey, value: until.millisecondsSinceEpoch.toString());
  }
  
  static Future<DateTime?> getPinLockoutUntil() async {
    final msStr = await _storage.read(key: _pinLockoutUntilKey);
    if (msStr == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(msStr));
  }
  
  // OTP Abuse Prevention
  static Future<List<DateTime>> getOtpAttemptTimestamps() async {
    final data = await _storage.read(key: _otpAttemptsKey);
    if (data == null || data.isEmpty) return [];
    
    // Format: comma separated ms since epoch
    final parts = data.split(',');
    return parts.map((p) => DateTime.fromMillisecondsSinceEpoch(int.parse(p))).toList();
  }
  
  static Future<int> recordOtpAttempt() async {
    final now = DateTime.now();
    final attempts = await getOtpAttemptTimestamps();
    
    // Prune attempts older than 1 hour
    final recentAttempts = attempts.where((d) => now.difference(d).inHours < 1).toList();
    recentAttempts.add(now);
    
    final data = recentAttempts.map((d) => d.millisecondsSinceEpoch.toString()).join(',');
    await _storage.write(key: _otpAttemptsKey, value: data);
    
    return recentAttempts.length;
  }
  
  static Future<void> setOtpLockoutUntil(DateTime until) async {
    await _storage.write(key: _otpLockoutUntilKey, value: until.millisecondsSinceEpoch.toString());
  }
  
  static Future<DateTime?> getOtpLockoutUntil() async {
    final msStr = await _storage.read(key: _otpLockoutUntilKey);
    if (msStr == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(msStr));
  }
  
  // Session Management
  static Future<void> saveSessionTimeout(int minutes) async {
    await _storage.write(key: _sessionTimeoutKey, value: minutes.toString());
  }
  
  static Future<int> getSessionTimeout() async {
    final timeoutStr = await _storage.read(key: _sessionTimeoutKey);
    return int.tryParse(timeoutStr ?? '5') ?? 5; // Default 5 minutes
  }
  
  static Future<void> updateLastActiveTime() async {
    await _storage.write(key: _lastActiveTimeKey, value: DateTime.now().millisecondsSinceEpoch.toString());
  }
  
  static Future<bool> isSessionExpired() async {
    final lastActiveStr = await _storage.read(key: _lastActiveTimeKey);
    if (lastActiveStr == null) return true;
    
    final lastActiveTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActiveStr));
    final timeoutMinutes = await getSessionTimeout();
    
    // If timeout is -1, it means 'Never'
    if (timeoutMinutes == -1) return false;
    // If timeout is 0, it means 'Immediately'
    if (timeoutMinutes == 0) return true;
    
    final difference = DateTime.now().difference(lastActiveTime).inMinutes;
    return difference >= timeoutMinutes;
  }
  
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  // Biometric & Privacy Settings
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }
  
  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }
  
  static Future<void> setScreenshotProtectionEnabled(bool enabled) async {
    await _storage.write(key: _screenshotProtectionKey, value: enabled.toString());
  }
  
  static Future<bool> isScreenshotProtectionEnabled() async {
    final val = await _storage.read(key: _screenshotProtectionKey);
    return val == 'true';
  }
}
