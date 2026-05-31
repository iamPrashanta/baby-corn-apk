import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';
import '../../domain/models/food_library_item.dart';
import '../providers/food_tracker_provider.dart';

class FoodLibraryTab extends ConsumerWidget {
  const FoodLibraryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(foodTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: standardFirstFoods.length,
      itemBuilder: (context, index) {
        final item = standardFirstFoods[index];
        final isIntroduced = records.any((r) => r.foodName.toLowerCase().contains(item.name.toLowerCase()));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? GlassColors.darkGlassSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isIntroduced
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIntroduced ? Icons.check_circle_rounded : Icons.restaurant_menu_rounded,
                color: isIntroduced ? Colors.green : (isDark ? Colors.white54 : Colors.black38),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Text(
                    isIntroduced ? "Introduced" : "Not Introduced",
                    style: TextStyle(
                      color: isIntroduced ? Colors.green : (isDark ? Colors.white54 : Colors.black54),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.isHighAllergyRisk) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Allergen",
                        style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: isIntroduced
                ? const Icon(Icons.check, color: Colors.green)
                : null,
          ),
        );
      },
    );
  }
}
