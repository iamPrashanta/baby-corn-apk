// lib/features/settings/presentation/screens/manage_babies_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/models/baby_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../records/presentation/providers/active_session_provider.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/utils/age_calculator.dart';

class ManageBabiesScreen extends ConsumerWidget {
  const ManageBabiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBabies = ref.watch(allBabiesProvider);
    final activeBaby = ref.watch(activeBabyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Babies'),
      ),
      body: allBabies.isEmpty
          ? _EmptyState(isDark: isDark)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              itemCount: allBabies.length,
              itemBuilder: (context, index) {
                final baby = allBabies[index];
                final isActive = baby.id == activeBaby?.id;

                return _BabyCard(
                  baby: baby,
                  isActive: isActive,
                  canDelete: allBabies.length > 1,
                  isDark: isDark,
                  onSelect: () => _selectBaby(context, ref, baby),
                  onEdit: () => context.push('/edit_baby/${baby.id}'),
                  onDelete: () => _showDeleteConfirm(context, ref, baby),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 80).ms)
                    .slideY(begin: 0.06, end: 0);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/onboarding?add=true'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Baby'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _selectBaby(
      BuildContext context, WidgetRef ref, BabyModel baby) async {
    final activeSession = ref.read(activeSessionProvider);
    if (activeSession != null && activeSession.isRunning) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          title: const Text('Timer Running'),
          content: const Text(
              'Stop the active timer before switching baby profiles.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(activeSessionProvider.notifier).cancelSession();
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Stop Timer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (result != true) return;
    }
    await ref.read(activeBabyProvider.notifier).setActiveBaby(baby.id);
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, BabyModel baby) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        title: const Text('Delete Baby Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${baby.name}\'s profile?'),
            const SizedBox(height: 12),
            const Text(
              '⚠ This will permanently delete all records associated with this baby.',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(activeBabyProvider.notifier).deleteBaby(baby.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Baby Card ────────────────────────────────────────────────────────────────

class _BabyCard extends StatelessWidget {
  final BabyModel baby;
  final bool isActive;
  final bool canDelete;
  final bool isDark;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BabyCard({
    required this.baby,
    required this.isActive,
    required this.canDelete,
    required this.isDark,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  Color _genderColor() {
    switch (baby.gender) {
      case 'Girl':
        return AppColors.primary.withOpacity(0.15);
      case 'Boy':
        return AppColors.primary.withOpacity(0.25);
      default:
        return AppColors.primary.withOpacity(0.1);
    }
  }

  Color _feedingColor() {
    switch (baby.feedingType) {
      case 'Breastmilk':
        return AppColors.secondary.withOpacity(0.15);
      case 'Formula':
        return AppColors.secondary.withOpacity(0.25);
      default:
        return AppColors.secondary.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final age = AgeCalculator.formatAge(baby.birthDate);

    return GestureDetector(
      onTap: onEdit,
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4.0),
        border: isActive
            ? Border.all(color: AppColors.primary, width: 2.5)
            : Border.all(color: Colors.transparent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primary.withOpacity(0.18)
                : Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name + age + menu ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: () {
                      final hasPhoto = baby.profileImagePath != null && File(baby.profileImagePath!).existsSync();
                      if (baby.profileImagePath != null && !hasPhoto) {
                        debugPrint('[BABY PHOTO MISSING] Using avatar fallback');
                      }
                      return hasPhoto
                          ? Image.file(
                              File(baby.profileImagePath!),
                              fit: BoxFit.cover,
                              width: 64,
                              height: 64,
                            )
                          : Center(
                              child: Text(
                                baby.avatarEmoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                            );
                    }(),
                  ),
                ),
                const SizedBox(width: 16),
                // Name + age
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              baby.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Removed Kebab menu
              ],
            ),
            const SizedBox(height: 16),

            // ── Badges row ───────────────────────────────────────
            Row(
              children: [
                _Badge(
                  label: baby.gender == 'Prefer not to say'
                      ? '💛 Any'
                      : baby.gender == 'Girl'
                          ? '👧 Girl'
                          : '👦 Boy',
                  color: _genderColor(),
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: '🍼 ${baby.feedingType}',
                  color: _feedingColor(),
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: '⚖️ ${baby.birthWeight.toStringAsFixed(1)} kg',
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ],
            ),

            // ── Set Active button (only if not active) ───────────
            if (!isActive) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onSelect,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Center(
                    child: Text(
                      'Set as Active',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }
}

// ─── Badge chip ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👶', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          const Text(
            'No babies yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Baby" to get started.',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
