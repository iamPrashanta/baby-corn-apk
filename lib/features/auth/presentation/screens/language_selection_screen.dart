// lib/features/auth/presentation/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/baby_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिन्दी'},
      {'code': 'bn', 'name': 'বাংলা'},
      {'code': 'te', 'name': 'తెలుగు'},
      {'code': 'ta', 'name': 'தமிழ்'},
      {'code': 'kn', 'name': 'ಕನ್ನಡ'},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectLanguage,
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose your preferred language.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return InkWell(
                      onTap: () async {
                        // Set locale
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(lang['code']!));

                        // Mark language as selected
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_selected_language', true);
                        debugPrint('🌐 [Language] Selected: ${lang['code']}');

                        if (!context.mounted) return;

                        final isOfflineMode = prefs.getBool('is_offline_mode') ?? false;

                        if (AppConfig.enableFirebaseAuth && !isOfflineMode) {
                          // FIX #2: Check Firebase auth state BEFORE routing.
                          // Previously this always routed to /auth even for
                          // signed-in users whose SharedPrefs were cleared.
                          debugPrint(
                              '🌐 [Language] Awaiting Firebase auth state...');
                          final currentUser = await FirebaseAuth.instance
                              .authStateChanges()
                              .first
                              .timeout(
                                const Duration(seconds: 5),
                                onTimeout: () {
                                  debugPrint(
                                      '⚠️ [Language] Firebase auth state timeout — routing to /auth');
                                  return null;
                                },
                              );

                          debugPrint(
                              '🌐 [Language] currentUser=${currentUser?.email}');

                          if (!context.mounted) return;

                          if (currentUser != null) {
                            // Already signed in — skip auth screen entirely
                            final hasBabies = ref
                                .read(babyRepositoryProvider)
                                .getBabies()
                                .isNotEmpty;
                            final route =
                                hasBabies ? '/home' : '/onboarding';
                            debugPrint(
                                '🌐 [Language] Already signed in → $route');
                            context.go(route);
                          } else {
                            // Not signed in — show Google sign-in
                            debugPrint(
                                '🌐 [Language] Not signed in → /auth');
                            context.go('/auth');
                          }
                        } else {
                          // Offline mode — route based on baby list
                          final hasBabies = ref
                              .read(babyRepositoryProvider)
                              .getBabies()
                              .isNotEmpty;
                          final route = hasBabies ? '/home' : '/onboarding';
                          debugPrint(
                              '🌐 [Language] Offline mode → $route');
                          context.go(route);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF252229) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Text(
                          lang['name']!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
