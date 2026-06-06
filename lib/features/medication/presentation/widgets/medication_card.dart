import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/medication_model.dart';
import '../../../../core/theme/glass_system/glass_styles.dart';
import '../../../../core/local_storage/hive_manager.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTap;
  final VoidCallback onTakeDose;
  final VoidCallback onMissDose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTap,
    required this.onTakeDose,
    required this.onMissDose,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final statusData = _calculateStatusAndNextDose(medication);
    final status = statusData['status'] as String;
    final nextDoseTime = statusData['nextDose'] as DateTime?;

    Color statusColor;
    switch (status) {
      case 'On Time':
        statusColor = Colors.green;
        break;
      case 'Due Soon':
        statusColor = Colors.orange;
        break;
      case 'Missed':
        statusColor = Colors.red;
        break;
      case 'Completed':
      default:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      decoration: GlassStyles.adaptiveGlassDecoration(context),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(4.0),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              _buildStatusChip(status, statusColor),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${medication.doseAmount} ${medication.doseUnit} • ${medication.scheduleType}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (nextDoseTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Next Dose: ${DateFormat('h:mm a').format(nextDoseTime)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: onTakeDose,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      label: const Text('Taken', style: TextStyle(color: Colors.green)),
                    ),
                    TextButton.icon(
                      onPressed: onMissDose,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Missed', style: TextStyle(color: Colors.red)),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                        if (value == 'history') onViewHistory();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                        const PopupMenuItem(value: 'history', child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 8), Text('View History')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.more_horiz, size: 20),
                            SizedBox(width: 4),
                            Text('More'),
                          ],
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

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStatusAndNextDose(MedicationModel med) {
    final now = DateTime.now();
    
    if (med.endDate != null && med.endDate!.isBefore(now)) {
      return {'status': 'Completed', 'nextDose': null};
    }

    final logs = HiveManager.getRecordsBox().values.where((r) => r.type == 'medication' && r.metadata['medicationId'] == med.id).toList();
    
    DateTime? nextDose;
    String status = 'On Time';
    
    // Calculate all dose times for today
    List<DateTime> todayDoses = [];
    for (final timeStr in med.times) {
      final parts = timeStr.split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        int hour = int.tryParse(timeParts[0]) ?? 8;
        int minute = int.tryParse(timeParts[1]) ?? 0;
        if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
        if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
        todayDoses.add(DateTime(now.year, now.month, now.day, hour, minute));
      }
    }
    todayDoses.sort();

    // Check for missed doses today (using the new 30 min rule)
    for (final doseTime in todayDoses) {
      if (now.isAfter(doseTime)) {
        final hasTakenLog = logs.any((l) {
            if (l.metadata['status'] != 'taken') return false;
            final stStr = l.metadata['scheduledTime'];
            if (stStr == null) return false;
            final st = DateTime.parse(stStr);
            return st.isAtSameMomentAs(doseTime);
        });
        
        final diffMins = now.difference(doseTime).inMinutes;
        if (!hasTakenLog && diffMins > 30) {
           status = 'Missed';
        }
      }
    }

    // Find next dose
    for (final doseTime in todayDoses) {
      if (doseTime.isAfter(now)) {
        nextDose = doseTime;
        break;
      }
    }
    if (nextDose == null && todayDoses.isNotEmpty) {
      // Next dose is tomorrow
      nextDose = todayDoses.first.add(const Duration(days: 1));
    }

    if (status != 'Missed' && nextDose != null) {
      if (nextDose.difference(now).inMinutes <= 30 && nextDose.difference(now).inMinutes >= 0) {
        status = 'Due Soon';
      }
    }

    return {'status': status, 'nextDose': nextDose};
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
