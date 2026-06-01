// features/records/presentation/widgets/add_record_modal.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/widgets/bouncing_button.dart';
import '../../../../core/design/components/dialogs/app_bottom_sheet.dart';
import '../providers/active_session_provider.dart';
import 'feeding_options_sheet.dart';

class AddRecordModal extends ConsumerWidget {
  final String? initialType;
  const AddRecordModal({super.key, this.initialType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBottomSheet(
      useGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log an activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.1, end: 0, duration: 250.ms),
          const SizedBox(height: 6),
          Text(
            'What happened?',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 15,
            ),
          )
              .animate()
              .fadeIn(duration: 250.ms, delay: 50.ms),
          const SizedBox(height: 24),

          // Active items — first row
          Row(
            children: [
              Expanded(
                child: _CategoryTile(
                  emoji: '🍼',
                  label: 'Feeding',
                  color: AppColors.feeding,
                  isActive: true,
                  isHighlighted: initialType == 'feeding',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (ctx) => const FeedingOptionsSheet(),
                    );
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 100.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 100.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '😴',
                  label: 'Sleep',
                  color: AppColors.sleep,
                  isActive: true,
                  isHighlighted: initialType == 'sleep',
                  onTap: () {
                    final notifier = ref.read(activeSessionProvider.notifier);
                    final state = ref.read(activeSessionProvider);
                    if (state != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stop current session first')));
                      return;
                    }
                    notifier.startSession('Sleep');
                    Navigator.pop(context);
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 150.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 150.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '🩲',
                  label: 'Diaper',
                  color: AppColors.diaper,
                  isActive: true,
                  isHighlighted: initialType == 'diaper',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/entry/diaper?status=Mixed');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 200.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 200.ms, curve: Curves.easeOutBack),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active items — second row (Output & Hygiene)
          Row(
            children: [
              Expanded(
                child: _CategoryTile(
                  emoji: '💦',
                  label: 'Urination',
                  color: AppColors.urination,
                  isActive: true,
                  isHighlighted: initialType == 'urination',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/entry/diaper?status=Wet');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 250.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 250.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '💩',
                  label: 'Stool',
                  color: AppColors.stool,
                  isActive: true,
                  isHighlighted: initialType == 'stool',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/entry/diaper?status=Dirty');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 300.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 300.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '🛁',
                  label: 'Bath',
                  color: Colors.lightBlue,
                  isActive: true,
                  isHighlighted: initialType == 'bath',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/entry/bath');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 350.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 350.ms, curve: Curves.easeOutBack),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Active items — third row (Development & Mood)
          Row(
            children: [
              Expanded(
                child: _CategoryTile(
                  emoji: '🤸',
                  label: 'Tummy',
                  color: AppColors.tertiary,
                  isActive: true,
                  isHighlighted: initialType == 'tummy_time',
                  onTap: () {
                    final notifier = ref.read(activeSessionProvider.notifier);
                    final state = ref.read(activeSessionProvider);
                    if (state != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stop current session first')));
                      return;
                    }
                    notifier.startSession('Tummy Time');
                    Navigator.pop(context);
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 400.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 400.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '😊',
                  label: 'Mood',
                  color: AppColors.mood,
                  isActive: true,
                  isHighlighted: initialType == 'mood',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/entry/mood');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 450.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 450.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '💉',
                  label: 'Vaccine',
                  color: AppColors.vaccine,
                  isActive: true,
                  isHighlighted: initialType == 'vaccine',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/vaccines');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 500.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 500.ms, curve: Curves.easeOutBack),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Active items — fourth row (Health)
          Row(
            children: [
              Expanded(
                child: _CategoryTile(
                  emoji: '💊',
                  label: 'Medicine',
                  color: AppColors.primary,
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/medications');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 550.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 550.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryTile(
                  emoji: '🩺',
                  label: 'Doctor',
                  color: const Color(0xFF6A4C93),
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/appointments');
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: 550.ms)
                    .scaleXY(begin: 0.9, end: 1.0, duration: 250.ms, delay: 550.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Pro Features ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.primary : AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '— Coming Soon',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white30 : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 200.ms, delay: 600.ms),
          const SizedBox(height: 12),

          // Coming Soon Pro Features - Row 1
          Row(
            children: [
              Expanded(child: _CategoryTile(emoji: '🎙️', label: 'Voice Log', color: Colors.indigo, isActive: false, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _CategoryTile(emoji: '🤖', label: 'AI Assist', color: AppColors.primary, isActive: false, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _CategoryTile(emoji: '📊', label: 'Insights', color: Colors.teal, isActive: false, onTap: () {})),
            ],
          ).animate().fadeIn(duration: 200.ms, delay: 650.ms),
          
          const SizedBox(height: 12),
          
          // Coming Soon Pro Features - Row 2
          Row(
            children: [
              Expanded(child: _CategoryTile(emoji: '🏥', label: 'Export', color: Colors.redAccent, isActive: false, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _CategoryTile(emoji: '🌙', label: 'Lullabies', color: Colors.blueGrey, isActive: false, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _CategoryTile(emoji: '📈', label: 'Growth', color: Colors.green, isActive: false, onTap: () {})),
            ],
          ).animate().fadeIn(duration: 200.ms, delay: 700.ms),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isActive;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncingButton(
      onPressed: isActive
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label is coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isHighlighted
                ? color.withOpacity(isDark ? 0.2 : 0.18)
                : color.withOpacity(isDark ? 0.08 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlighted
                  ? color.withOpacity(0.4)
                  : color.withOpacity(isDark ? 0.12 : 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? (isDark ? Colors.white70 : null)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
