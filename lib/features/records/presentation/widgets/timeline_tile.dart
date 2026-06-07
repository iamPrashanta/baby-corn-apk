import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radius.dart';

class TimelineTile extends ConsumerWidget {
  final RecordModel record;
  final bool isLast;
  
  const TimelineTile({
    super.key, 
    required this.record, 
    this.isLast = false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (emoji, label, subtitle, color) = _recordMeta(record);
    final timeStr = DateFormat.jm().format(record.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showDeleteConfirm(context, ref, record),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          if (subtitle.isNotEmpty)
                            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          if (record.metadata['note'] != null &&
                              record.metadata['note'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '"${record.metadata['note']}"',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, RecordModel record) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          title: Text(
            'Delete Activity',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this activity? This cannot be undone.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ref.read(recordsProvider.notifier).deleteRecord(record.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  (String, String, String, Color) _recordMeta(RecordModel r) {
    switch (r.type.toLowerCase()) {
      case 'left feeding':
      case 'right feeding':
      case 'feeding':
        final method = r.metadata['side'] ?? r.metadata['method'] ?? r.metadata['originalType'] ?? 'Feeding';
        final dur = r.metadata['durationSeconds'];
        final durMin = dur != null ? (dur as int) ~/ 60 : r.metadata['duration'];
        final amount = r.metadata['amount']?.toString() ?? '';
        final leftSec = r.metadata['leftDurationSeconds'] as int?;
        final rightSec = r.metadata['rightDurationSeconds'] as int?;
        
        // Build subtitle: show amount if present, else duration
        String sub;
        if (amount.isNotEmpty) {
          final unit = (method == 'Bottle') ? 'ml' : '';
          sub = amount.contains(RegExp(r'[a-zA-Z]')) ? '$method • $amount' : '$method • $amount$unit';
        } else if (leftSec != null || rightSec != null) {
          final lMin = leftSec != null ? leftSec ~/ 60 : 0;
          final rMin = rightSec != null ? rightSec ~/ 60 : 0;
          if (lMin > 0 && rMin > 0) {
            sub = 'L: ${lMin}m • R: ${rMin}m';
          } else if (lMin > 0) {
            sub = 'Left • ${lMin}m';
          } else if (rMin > 0) {
            sub = 'Right • ${rMin}m';
          } else {
            sub = '$method • <1m';
          }
        } else if (dur != null) {
          final d = dur as int;
          if (d < 60) {
            sub = '$method • ${d}s';
          } else {
            final m = d ~/ 60;
            final s = d % 60;
            sub = s > 0 ? '$method • ${m}m ${s}s' : '$method • ${m}m';
          }
        } else if (durMin != null && durMin > 0) {
          sub = '$method • ${durMin}m';
        } else {
          sub = '$method';
        }
        return ('🍼', 'Feeding', sub, AppColors.feeding);
      case 'sleep':
        final durSec = r.metadata['durationSeconds'];
        final durMin = durSec != null ? (durSec as int) ~/ 60 : r.metadata['durationMinutes'];
        String sleepDur = 'Sleep logged';
        if (durSec != null) {
          final d = durSec as int;
          if (d < 60) {
            sleepDur = '${d}s';
          } else {
            final m = d ~/ 60;
            final s = d % 60;
            sleepDur = s > 0 ? '${m}m ${s}s' : '${m}m';
          }
        } else if (durMin != null && durMin > 0) {
          sleepDur = '${durMin} mins';
        }
        return ('😴', 'Sleep', sleepDur, AppColors.sleep);
      case 'tummy_time':
      case 'tummy time':
        final dur = r.metadata['durationSeconds'];
        final durMin = dur != null ? (dur as int) ~/ 60 : null;
        String ttDur = '';
        if (dur != null) {
          final d = dur as int;
          if (d < 60) {
            ttDur = '${d}s';
          } else {
            final m = d ~/ 60;
            final s = d % 60;
            ttDur = s > 0 ? '${m}m ${s}s' : '${m}m';
          }
        } else if (durMin != null && durMin > 0) {
          ttDur = '${durMin} mins';
        }
        return ('🤸', 'Tummy Time', ttDur, AppColors.tertiary);
      case 'diaper':
        final status = r.metadata['status'] as String? ?? 'Diaper changed';
        if (status == 'Wet') {
          return ('💦', 'Urination', 'Wet diaper', AppColors.urination);
        } else if (status == 'Dirty') {
          return ('💩', 'Stool', 'Dirty diaper', AppColors.stool);
        } else if (status == 'Mixed') {
          return ('🩲', 'Diaper', 'Mixed diaper', AppColors.diaper);
        }
        return ('🩲', 'Diaper', status, AppColors.diaper);
      case 'bath':
        final type = r.metadata['type'] as String? ?? 'Bath';
        final hair = r.metadata['hairWashed'] == true ? 'Hair washed' : '';
        final lotion = r.metadata['lotionApplied'] == true ? 'Lotion applied' : '';
        final parts = [if(hair.isNotEmpty) hair, if(lotion.isNotEmpty) lotion].join(' • ');
        return ('🛁', type, parts.isNotEmpty ? parts : 'Bath logged', Colors.lightBlue);
      case 'mood':
        final emoji = r.metadata['emoji'] as String? ?? '😊';
        final mood = r.metadata['mood'] as String? ?? 'Happy';
        final intensity = r.metadata['intensity'] as String? ?? 'Moderate';
        return (emoji, 'Mood: $mood', '$intensity intensity', AppColors.mood);
      case 'vaccine':
        final vName = r.metadata['vaccineName'] as String? ?? 'Vaccine';
        final batch = r.metadata['batchNumber'] as String? ?? '';
        final subtitle = batch.isNotEmpty ? 'Batch: $batch' : 'Vaccine Administered';
        return ('💉', vName, subtitle, AppColors.vaccine);
      case 'appointment':
        final docName = r.metadata['doctorName'] as String? ?? '';
        final spec = r.metadata['specialization'] as String? ?? '';
        final location = r.metadata['location'] as String? ?? '';
        final subtitleParts = [if (spec.isNotEmpty) spec, if (location.isNotEmpty) location];
        return ('🩺', 'Doctor Appointment', docName.isNotEmpty ? [docName, ...subtitleParts].join(' • ') : subtitleParts.join(' • '), AppColors.primary);
      case 'medication':
      case 'medicine':
        final mName = r.metadata['medicationName'] ?? r.metadata['name'] ?? 'Medication';
        final status = r.metadata['status'] ?? 'taken';
        
        String subtitle = 'Status: $status';
        if (status == 'taken' && r.metadata['takenTime'] != null) {
          final tTime = DateTime.tryParse(r.metadata['takenTime'].toString());
          if (tTime != null) {
            subtitle = 'Taken at ${DateFormat.jm().format(tTime)}';
          }
        } else if (status == 'missed') {
          subtitle = 'Missed Dose';
        } else if (status == 'skipped') {
          subtitle = 'Skipped Dose';
        }

        Color statusColor = AppColors.primary;
        if (status == 'missed') statusColor = Colors.redAccent;
        if (status == 'taken') statusColor = Colors.green;

        return ('💊', mName, subtitle, statusColor);
      default:
        return ('📝', 'Activity', '', Colors.grey);
    }
  }
}

class EmptyTimelineState extends StatelessWidget {
  const EmptyTimelineState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No records yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your baby\'s first moments.\nTap the + button to log feeding, sleep, or diapers.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
