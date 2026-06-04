// core/local_storage/secure_storage_manager.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static const _storage = FlutterSecureStorage();
  
  // OTP Abuse Prevention Keys
  static const String _otpAttemptsKey = 'otp_attempts_timestamps';
  static const String _otpLockoutUntilKey = 'otp_lockout_until';
  // Security & Privacy Keys
  static const String _screenshotProtectionKey = 'screenshot_protection';


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
  

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  // Security & Privacy Settings
  static Future<void> setScreenshotProtectionEnabled(bool enabled) async {
    await _storage.write(key: _screenshotProtectionKey, value: enabled.toString());
  }
  
  static Future<bool> isScreenshotProtectionEnabled() async {
    final val = await _storage.read(key: _screenshotProtectionKey);
    return val == 'true';
  }
}
