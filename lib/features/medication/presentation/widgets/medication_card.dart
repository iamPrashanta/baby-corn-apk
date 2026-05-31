import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/medication_model.dart';
import '../../../../core/theme/glass_system/glass_styles.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTap;
  final VoidCallback onTakeDose;
  final VoidCallback onDuplicate;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTap,
    required this.onTakeDose,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowStock =
        medication.remainingQuantity <= medication.lowStockThreshold;

    int? estimatedDaysRemaining;
    if (medication.times.isNotEmpty && medication.doseAmount > 0) {
      final dailyConsumption = medication.times.length * medication.doseAmount;
      estimatedDaysRemaining =
          (medication.remainingQuantity / dailyConsumption).floor();
    }

    DateTime? estimatedFinishDate;
    if (estimatedDaysRemaining != null) {
      estimatedFinishDate =
          DateTime.now().add(Duration(days: estimatedDaysRemaining));
    }

    return Container(
      decoration: GlassStyles.adaptiveGlassDecoration(context),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(medication.type),
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  medication.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: onDuplicate,
                                tooltip: 'Duplicate Medication',
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${medication.doseAmount} ${medication.doseUnit} • ${medication.scheduleType}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Course Progress
                if (medication.endDate != null) ...[
                  const SizedBox(height: 16),
                  _buildCourseProgress(context),
                ],

                const SizedBox(height: 16),

                // Stock Info & Take Dose
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${medication.remainingQuantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: isLowStock
                                          ? Colors.orangeAccent
                                          : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (isLowStock) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orangeAccent, size: 16),
                              ]
                            ],
                          ),
                          if (estimatedFinishDate != null)
                            Text(
                              '≈ ${estimatedDaysRemaining!} days (May finish ${DateFormat('MMM d').format(estimatedFinishDate)})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: onTakeDose,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Take Dose'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseProgress(BuildContext context) {
    final start = medication.startDate;
    final end = medication.endDate!;
    final totalDays =
        end.difference(start).inDays > 0 ? end.difference(start).inDays : 1;
    final completedDays =
        DateTime.now().difference(start).inDays.clamp(0, totalDays);

    final progress = completedDays / totalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Course Progress',
                style: Theme.of(context).textTheme.bodySmall),
            Text('$completedDays / $totalDays days',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            color: progress >= 1.0
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
        return Icons.medication;
      case 'capsule':
        return Icons.medication_liquid;
      case 'syrup':
        return Icons.water_drop;
      case 'drops':
        return Icons.opacity;
      case 'injection':
        return Icons.vaccines;
      case 'powder':
        return Icons.scatter_plot;
      case 'supplement':
        return Icons.health_and_safety;
      default:
        return Icons.local_pharmacy;
    }
  }
}
