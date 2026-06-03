import 'package:flutter/material.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';
import '../../domain/models/food_library_item.dart';

enum PureeType { single, twoIngredient, threeIngredient, fourIngredient }

class PureeRecipeList extends StatelessWidget {
  final PureeType type;

  const PureeRecipeList({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PureeType.single:
        return _buildSingleIngredientList(context);
      case PureeType.twoIngredient:
        return _buildListFromData(
          context,
          "2-Ingredient Purees",
          [
            "Fruit: Apple + Carrot",
            "Fruit: Pear + Pumpkin",
            "Fruit: Banana + Avocado",
            "Fruit: Papaya + Carrot",
            "Veg: Pumpkin + Carrot",
            "Veg: Sweet Potato + Peas",
            "Veg: Pear + Spinach",
            "Veg: Beetroot + Sweet Potato",
            "Veg: Apple + Beetroot",
          ],
        );
      case PureeType.threeIngredient:
        return _buildListFromData(
          context,
          "3-Ingredient Purees",
          [
            "Apple + Beetroot + Carrot",
            "Pear + Sweet Potato + Pumpkin",
            "Banana + Papaya + Avocado",
            "Pumpkin + Peas + Spinach",
            "Sweet Potato + Carrot + Apple",
            "Pear + Beetroot + Banana",
            "Carrot + Peas + Pumpkin",
            "Pear + Papaya + Banana",
            "Pumpkin + Apple + Spinach",
            "Sweet Potato + Carrot + Beetroot",
          ],
        );
      case PureeType.fourIngredient:
        return _buildListFromData(
          context,
          "4-Ingredient Purees",
          [
            "Carrot + Pumpkin + Banana + Sweet Potato",
            "Carrot + Apple + Pumpkin + Pear",
            "Pear + Papaya + Banana + Avocado",
            "Carrot + Sweet Potato + Spinach + Beetroot",
            "Pumpkin + Peas + Spinach + Apple",
            "Carrot + Pumpkin + Spinach + Beetroot",
            "Carrot + Apple + Beetroot + Pear",
            "Pear + Papaya + Banana + Pumpkin",
            "Carrot + Sweet Potato + Spinach + Peas",
            "Banana + Pear + Avocado + Apple",
          ],
        );
    }
  }

  Widget _buildSingleIngredientList(BuildContext context) {
    final Map<String, String> data = {
      "Carrot Puree": "Vitamin A, eye health",
      "Apple Puree": "Fiber, digestion",
      "Beetroot Puree": "Iron, folate",
      "Pumpkin Puree": "Vitamin A, immunity",
      "Spinach Puree": "Iron, calcium",
      "Peas Puree": "Protein, fiber",
      "Pear Puree": "Gentle on tummy",
      "Banana Puree": "Energy, potassium",
      "Papaya Puree": "Digestion support",
      "Sweet Potato Puree": "Fiber, Vitamin A",
    };

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final key = data.keys.elementAt(index);
        final value = data[key]!;
        return _buildRecipeCard(context, key, value);
      },
    );
  }

  Widget _buildListFromData(BuildContext context, String title, List<String> items) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildRecipeCard(context, items[index], null);
      },
    );
  }

  Widget _buildRecipeCard(BuildContext context, String title, String? subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    FoodLibraryItem? matchedItem;
    for (var item in standardFirstFoods) {
      if (title.toLowerCase().contains(item.name.toLowerCase())) {
        matchedItem = item;
        break;
      }
    }
    
    final bool isHighAllergyRisk = matchedItem?.isHighAllergyRisk ?? false;
    final String ageReq = matchedItem?.ageRecommendation ?? "6+ Months";

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Age: $ageReq",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null || isHighAllergyRisk) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (subtitle != null)
                Text(
                  "Benefits: $subtitle",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              if (isHighAllergyRisk)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "High Allergy Risk",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

