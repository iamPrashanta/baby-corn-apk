// features/records/presentation/screens/records_timeline_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../../domain/models/record_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/timeline_tile.dart';

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
                    return const EmptyTimelineState();
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
                            return TimelineTile(record: e.value, isLast: isLast)
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


