import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class BabyCryLanguageScreen extends StatelessWidget {
  const BabyCryLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> cries = [
      {
        'sound': 'Neeeeh',
        'meaning': 'Hungry',
        'icon': Icons.restaurant_menu_rounded,
        'color': AppColors.feeding,
        'description':
            'Triggered by the sucking reflex. As the baby pushes their tongue to the roof of their mouth, the sound "Neh" is produced. Look for rooting behaviors or lip smacking.',
      },
      {
        'sound': 'Owwwh',
        'meaning': 'Sleepy',
        'icon': Icons.bedtime_rounded,
        'color': AppColors.sleep,
        'description':
            'Triggered by a yawn reflex. Sounds like a yawning sigh ("Owh" or "Oah"). Look for rubbing eyes, yawning, or jerky movements indicating tiredness.',
      },
      {
        'sound': 'Ehhh',
        'meaning': 'Need to Burp',
        'icon': Icons.air_rounded,
        'color': Colors.teal,
        'description':
            'Triggered by a chest spasm as the baby tries to push trapped air out of their stomach. Try placing them over your shoulder and gently patting their back.',
      },
      {
        'sound': 'Eairrrh',
        'meaning': 'Gas / Lower Abdominal Pain',
        'icon': Icons.healing_rounded,
        'color': Colors.deepOrange,
        'description':
            'Triggered by lower bowel tension. The cry often sounds strained or groaning. The baby will typically pull their knees to their chest or arch their back in discomfort.',
      },
      {
        'sound': 'Hehhh',
        'meaning': 'Physical Discomfort',
        'icon': Icons.thermostat_rounded,
        'color': Colors.amber.shade700,
        'description':
            'Triggered by a stress reflex. This indicates the baby is uncomfortable—often because they are too hot, too cold, or have a wet/soiled diaper. Check their temperature and diaper.',
      },
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Understand Your Baby',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  'Based on the Dunstan Baby Language, all newborns produce 5 universal vocal reflexes before crying. Listen for these subtle sounds to quickly identify what your baby needs.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cry = cries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (cry['color'] as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                cry['icon'] as IconData,
                                color: cry['color'] as Color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '"${cry['sound']}"',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (cry['color'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      cry['meaning'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: cry['color'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cry['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1),
                );
              },
              childCount: cries.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom nav padding
      ],
    );
  }
}
