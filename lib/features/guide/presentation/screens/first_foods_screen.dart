import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/layouts/custom_app_bar.dart';
import '../widgets/puree_recipe_list.dart';
import '../widgets/food_library_tab.dart';

class FirstFoodsScreen extends StatelessWidget {
  const FirstFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: CustomAppBar(
          title: "First Foods (6+ Months)",
          actions: [
            IconButton(
              icon: const Icon(Icons.assignment_turned_in_rounded),
              tooltip: "Food Tracker",
              onPressed: () => context.push('/guide/food_tracker'),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: const [
              Tab(text: "Library"),
              Tab(text: "Single"),
              Tab(text: "2-Ingredient"),
              Tab(text: "3-Ingredient"),
              Tab(text: "4-Ingredient"),
              Tab(text: "Important Notes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const FoodLibraryTab(),
            const PureeRecipeList(type: PureeType.single),
            const PureeRecipeList(type: PureeType.twoIngredient),
            const PureeRecipeList(type: PureeType.threeIngredient),
            const PureeRecipeList(type: PureeType.fourIngredient),
            _buildImportantNotes(context),
          ],
        ),
        floatingActionButton: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/guide/food_tracker'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.track_changes_rounded),
              label: const Text("Food Tracker"),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImportantNotes(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      children: [
        _buildNoteItem(context, "Start solids after 6 months.", Icons.calendar_month_rounded),
        _buildNoteItem(context, "Introduce one new food every 3 days to monitor for allergies.", Icons.warning_rounded),
        _buildNoteItem(context, "No salt.", Icons.do_not_disturb_alt_rounded),
        _buildNoteItem(context, "No sugar.", Icons.do_not_disturb_alt_rounded),
        _buildNoteItem(context, "No honey before 1 year (risk of botulism).", Icons.do_not_disturb_alt_rounded),
        _buildNoteItem(context, "Steam or boil vegetables before blending to make them easily digestible.", Icons.local_fire_department_rounded),
        _buildNoteItem(context, "Fruits like banana, pear, papaya, and avocado can be mashed directly.", Icons.restaurant_rounded),
        _buildNoteItem(context, "Stop and consult a pediatrician immediately if rash, vomiting, diarrhea, or breathing issues occur.", Icons.health_and_safety_rounded, isAlert: true),
      ],
    );
  }

  Widget _buildNoteItem(BuildContext context, String text, IconData icon, {bool isAlert = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isAlert ? Colors.redAccent : (isDark ? Colors.white70 : AppColors.lightTextPrimary);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: color,
                fontWeight: isAlert ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
