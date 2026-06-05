// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/services/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(); // Can be used to inject the service
});
