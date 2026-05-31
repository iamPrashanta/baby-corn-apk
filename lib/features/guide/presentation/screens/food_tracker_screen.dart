import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/models/food_intro_record.dart';
import '../providers/food_tracker_provider.dart';
import 'add_food_dialog.dart';
import '../widgets/reaction_symptoms_dialog.dart';

class FoodTrackerScreen extends ConsumerWidget {
  const FoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(foodTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: "Food Introduction Tracker"),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No foods tracked yet.",
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return _buildRecordCard(context, ref, records[index]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddFoodDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Log New Food"),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, WidgetRef ref, FoodIntroRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (record.status == FoodIntroStatus.safe) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = "Safe ✅";
    } else if (record.status == FoodIntroStatus.reaction) {
      statusColor = Colors.red;
      statusIcon = Icons.warning_rounded;
      statusText = "Reaction ⚠️";
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.visibility_rounded;
      
      final now = DateTime.now();
      final difference = now.difference(record.dateIntroduced).inHours;
      
      if (difference < 24) {
        statusText = "Day 1";
      } else if (difference < 48) {
        statusText = "Day 2";
      } else if (difference < 72) {
        statusText = "Day 3";
      } else {
        statusText = "Pending";
      }
    }

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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          record.foodName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Introduced: ${DateFormat.yMMMd().format(record.dateIntroduced)}",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (record.symptoms.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "Symptoms: ${record.symptoms.join(', ')}",
                  style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                ),
              ]
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (record.status != FoodIntroStatus.reaction)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final symptoms = await showDialog<List<String>>(
                        context: context,
                        builder: (ctx) => const ReactionSymptomsDialog(),
                      );
                      
                      if (symptoms != null && symptoms.isNotEmpty) {
                        final updated = record.copyWith(
                          status: FoodIntroStatus.reaction,
                          symptoms: symptoms,
                        );
                        ref.read(foodTrackerProvider.notifier).updateRecord(updated);
                      }
                    },
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text("Log Reaction"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                      elevation: 0,
                    ),
                  ),
                if (record.status == FoodIntroStatus.observing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final updated = record.copyWith(status: FoodIntroStatus.safe);
                        ref.read(foodTrackerProvider.notifier).updateRecord(updated);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text("Mark as Safe Early"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade900,
                        elevation: 0,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    ref.read(foodTrackerProvider.notifier).deleteRecord(record.id);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete Record"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

