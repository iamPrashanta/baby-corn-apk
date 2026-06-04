import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/components/dialogs/app_bottom_sheet.dart';
import '../providers/active_session_provider.dart';

class FeedingOptionsSheet extends ConsumerWidget {
  const FeedingOptionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBottomSheet(
      useGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeding?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the feeding method',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  emoji: '🤱',
                  label: 'Left Breast',
                  subtitle: 'Starts timer',
                  onTap: () {
                    final state = ref.read(activeSessionProvider);
                    if (state != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stop current session first')),
                      );
                      return;
                    }
                    ref.read(activeSessionProvider.notifier).startSession(
                      'Left Feeding',
                      metadata: {'side': 'Left Breast'},
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionTile(
                  emoji: '🤱',
                  label: 'Right Breast',
                  subtitle: 'Starts timer',
                  onTap: () {
                    final state = ref.read(activeSessionProvider);
                    if (state != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stop current session first')),
                      );
                      return;
                    }
                    ref.read(activeSessionProvider.notifier).startSession(
                      'Right Feeding',
                      metadata: {'side': 'Right Breast'},
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  emoji: '🍼',
                  label: 'Bottle',
                  subtitle: 'Log ml / oz',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/feeding-entry', extra: 'Bottle');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionTile(
                  emoji: '🥣',
                  label: 'Solid',
                  subtitle: 'Log food / amount',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/feeding-entry', extra: 'Solid');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.feeding.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.feeding.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
