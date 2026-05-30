// features/records/presentation/screens/records_timeline_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecordsTimelineScreen extends ConsumerWidget {
  const RecordsTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final filterDate = ref.watch(timelineFilterDateProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      if (filterDate != null) {
                        ref.read(timelineFilterDateProvider.notifier).state = null;
                        return;
                      }

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        ref.read(timelineFilterDateProvider.notifier).state = picked;
                      }
                    },
                    icon: Icon(filterDate != null ? Icons.close_rounded : Icons.filter_list_rounded, size: 20),
                    label: Text(filterDate != null ? DateFormat('MMM d').format(filterDate) : 'Filter Date'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: filterDate != null ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: recordsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (records) {
                  if (records.isEmpty) {
                    return _EmptyTimelineState();
                  }

                  // Group by date
                  final grouped = <String, List<RecordModel>>{};
                  for (final r in records) {
                    final dateKey = DateFormat('EEEE, d MMMM').format(r.timestamp);
                    grouped.putIfAbsent(dateKey, () => []).add(r);
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          ...entry.value.asMap().entries.map((e) {
                            final isLast = e.key == entry.value.length - 1;
                            return _TimelineTile(record: e.value, isLast: isLast)
                                .animate()
                                .fadeIn(duration: 300.ms, delay: (e.key * 100).ms)
                                .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic, delay: (e.key * 100).ms);
                          }),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TIMELINE TILE
// ─────────────────────────────────────────────────────────
class _TimelineTile extends ConsumerWidget {
  final RecordModel record;
  final bool isLast;
  const _TimelineTile({required this.record, this.isLast = false});

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
            child: Dismissible(
              key: Key(record.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Activity'),
                      content: const Text('Are you sure you want to delete this activity? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
                return confirm;
              },
              onDismissed: (_) {
                ref.read(recordsProvider.notifier).deleteRecord(record.id);
              },
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: AppRadius.cardBorder,
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
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
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showDeleteConfirm(context, ref),
                          child: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20),
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

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: const Text('Are you sure you want to delete this activity? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(recordsProvider.notifier).deleteRecord(record.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
        return ('🍼', 'Feeding', durMin != null && durMin > 0 ? '$method • ${durMin}m' : '$method', AppColors.feeding);
      case 'sleep':
        final durSec = r.metadata['durationSeconds'];
        final durMin = durSec != null ? (durSec as int) ~/ 60 : r.metadata['durationMinutes'];
        return ('😴', 'Sleep', durMin != null && durMin > 0 ? '${durMin} mins' : 'Sleep logged', AppColors.sleep);
      case 'tummy_time':
      case 'tummy time':
        final dur = r.metadata['durationSeconds'];
        final durMin = dur != null ? (dur as int) ~/ 60 : null;
        return ('🤸', 'Tummy Time', durMin != null && durMin > 0 ? '${durMin} mins' : '', AppColors.tertiary);
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
      default:
        return ('📝', 'Activity', '', Colors.grey);
    }
  }
}

// ─────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────
class _EmptyTimelineState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Soft illustration substitute
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
