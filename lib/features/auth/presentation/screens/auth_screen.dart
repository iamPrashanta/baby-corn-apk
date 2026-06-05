// lib/features/auth/presentation/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';
import '../../data/repositories/baby_repository.dart';
import '../../domain/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await AuthService.signInWithGoogle(context);

      if (user == null) {
        // User cancelled the sign-in dialog
        debugPrint('🔑 [Auth] User cancelled sign-in');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('===== GOOGLE LOGIN AUDIT =====');
      debugPrint('🔑 Firebase sign-in success: ${user.email}');
      debugPrint('🔑 Firebase UID: ${user.uid}');
      debugPrint('==============================');

      if (!mounted) return;
      setState(() => _isLoading = false);

      final repo = BabyRepository();
      final hasBabies = repo.getBabies().isNotEmpty;

      if (hasBabies) {
         context.go('/home');
      } else {
         context.go('/onboarding');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [Auth Audit] FirebaseAuthException: Code=${e.code}, Message=${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Authentication failed.';
      });
    } on FirebaseException catch (e) {
      debugPrint('❌ [Auth Audit] FirebaseException during Sync: Code=${e.code}, Message=${e.message}');
      if (e.code == 'permission-denied') {
        debugPrint('⚠️ [Auth Audit] Firebase Rules or App Check failure detected!');
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Cloud Sync Failed: ${e.message}';
      });
    } catch (e, st) {
      debugPrint('GOOGLE LOGIN ERROR: $e');
      debugPrint(st.toString());

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _continueOffline() async {
    // Skip Firebase authentication and PIN entirely for offline mode
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_offline_mode', true);
    
    if (!mounted) return;
    
    final repo = BabyRepository();
    final hasBabies = repo.getBabies().isNotEmpty;
    
    if (hasBabies) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.4),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(isDark ? 0.2 : 0.4),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 100),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // App Icon / Logo Area
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark
                            ? GlassColors.darkGlassSurface
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.child_care_rounded,
                          size: 56, color: AppColors.primary),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),
                  ),
                  const SizedBox(height: 32),

                  // Welcome Text
                  Text(
                    'Welcome to\nBaby Corn',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 16),

                  Text(
                    'Track your baby\'s journey seamlessly, synced across your family.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const Spacer(flex: 2),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Google Sign-In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.black : Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google 'G' Icon (Using flutter default icon or generic user icon since no asset exists)
                              Icon(Icons.g_mobiledata_rounded, size: 28),
                              const SizedBox(width: 8),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  // Offline Mode Button
                  TextButton(
                    onPressed: _isLoading ? null : _continueOffline,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0)),
                    ),
                    child: Text(
                      'Use Offline Mode',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
