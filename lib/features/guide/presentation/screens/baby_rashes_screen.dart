import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class BabyRashesScreen extends StatelessWidget {
  const BabyRashesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> rashes = [
      {
        'title': 'Cradle Cap',
        'icon': Icons.face_retouching_natural_rounded,
        'description': 'A common scalp condition in the first 3 months. Presents with yellow or white greasy scales surrounded by a rash. It does not cause pain or itching and usually resolves on its own within a few months.',
      },
      {
        'title': 'Milia (Baby Face Bumps)',
        'icon': Icons.fiber_manual_record_rounded,
        'description': 'Tiny white bumps (cysts) on the surface, usually on the nose. Caused by blocked pores. Harmless, painless, and usually lasts just a few weeks.',
      },
      {
        'title': 'Baby Acne',
        'icon': Icons.face_rounded,
        'description': 'Small inflamed bumps on face, neck, back, and chest, showing up in the first 2-4 weeks. Caused by maternal hormones. Usually resolves on its own in a few weeks.',
      },
      {
        'title': 'Diaper Rash',
        'icon': Icons.baby_changing_station_rounded,
        'description': 'Very common. Keep skin clean/dry, change diapers quickly, apply barrier cream. Increase airflow by letting baby go diaper-free or using larger diapers.',
      },
      {
        'title': 'Baby Eczema',
        'icon': Icons.water_drop_rounded,
        'description': 'Atopic dermatitis looking like dry, scaly, itchy skin on cheeks, scalp, or skin folds. Manage with daily warm baths, mild cleanser, and fragrance-free ointment.',
      },
      {
        'title': 'Erythema Toxicum',
        'icon': Icons.grain_rounded,
        'description': 'Appears around day 2-3 as flat discolored areas turning into raised spots or pus-filled blisters with a blotchy area. Resolves on its own in a week but may recur.',
      },
      {
        'title': 'Salmon Patches',
        'icon': Icons.favorite_rounded,
        'description': 'Stork bite or angel kiss. Red patches on forehead, eyelids, back of neck caused by stretched blood vessels. No treatment needed, fades within 18 months.',
      },
      {
        'title': 'Roseola',
        'icon': Icons.thermostat_rounded,
        'description': 'Viral infection causing sudden high fever for 3-4 days. Once fever subsides, a rash develops for 2-4 days. Contagious until 24 hrs after fever ends.',
      },
      {
        'title': 'Congenital Melanocytosis',
        'icon': Icons.brush_rounded,
        'description': 'Irregular blue/blue-gray spots often on lower back. Might be mistaken for bruising. Fades in the first year and disappears by adolescence.',
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
                  'Common Newborn Rashes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  'Throughout your baby’s first year, their skin plays host to a variety of conditions. By and large, they are harmless, temporary, and resolve without any treatment.',
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
                final rash = rashes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
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
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                rash['icon'] as IconData,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                rash['title'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rash['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1),
                );
              },
              childCount: rashes.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Tips for Reducing Rashes', isDark),
                const SizedBox(height: 12),
                _buildBulletPoint('Keep baby clean and dry: bathe daily, pat dry, and moisturize', isDark),
                _buildBulletPoint('Change wet and soiled diapers as soon as possible', isDark),
                _buildBulletPoint('Avoid scents and additives in detergents and soaps', isDark),
                _buildBulletPoint('Dress in breathable fabrics to avoid overheating', isDark),
                _buildBulletPoint('Keep up to date on vaccinations', isDark),
                
                const SizedBox(height: 32),
                
                _buildSectionTitle('When To Ask For Help', isDark),
                const SizedBox(height: 12),
                _buildBulletPoint('Fever: may suggest the presence of infection', isDark),
                _buildBulletPoint('Long-lasting or painful rash: persists beyond typical time frame', isDark),
                _buildBulletPoint('Spreading: spreads significantly, especially hives near the mouth', isDark),
                _buildBulletPoint('Trouble breathing: coughing, wheezing or respiratory problems', isDark),
                _buildBulletPoint('Behavioral changes: stiff neck, sensitivity to light, or shaking', isDark),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
