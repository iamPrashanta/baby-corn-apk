import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';
import '../../domain/models/food_library_item.dart';
import '../providers/food_tracker_provider.dart';

class FoodLibraryTab extends ConsumerStatefulWidget {
  const FoodLibraryTab({super.key});

  @override
  ConsumerState<FoodLibraryTab> createState() => _FoodLibraryTabState();
}

class _FoodLibraryTabState extends ConsumerState<FoodLibraryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(foodTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFoods = standardFirstFoods.where((food) {
      return food.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: "Search food...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? GlassColors.darkGlassSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredFoods.length,
            itemBuilder: (context, index) {
              final item = filteredFoods[index];
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isIntroduced
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.imageAssetPath != null
                        ? Image.asset(item.imageAssetPath!, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
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
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
