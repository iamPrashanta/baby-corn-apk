import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/records/domain/models/record_model.dart';

class WidgetService {
  static const String appGroupId = 'group.com.example.babycorn'; // For iOS
  static const String androidWidgetName = 'BabyCornWidget';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error initializing HomeWidget: $e');
    }
  }

  static Future<void> updateWidgetData(List<RecordModel> records) async {
    try {
      final now = DateTime.now();
      
      // Calculate sleep today
      int sleepMinutesToday = 0;
      DateTime? lastFeed;

      for (var record in records) {
        if (record.timestamp.year == now.year &&
            record.timestamp.month == now.month &&
            record.timestamp.day == now.day) {
          
          final type = record.type.toLowerCase();
          
          if (type.contains('sleep')) {
             final dur = record.metadata['durationSeconds'];
             final min = record.metadata['durationMinutes'];
             if (dur != null) {
               sleepMinutesToday += (dur as int) ~/ 60;
             } else if (min != null) {
               sleepMinutesToday += min as int;
             }
          }
        }

        // Find last feed
        if (lastFeed == null && record.type.toLowerCase().contains('feed')) {
          lastFeed = record.timestamp;
        }
      }

      // Format sleep
      final sleepStr = sleepMinutesToday >= 60 
        ? '${sleepMinutesToday ~/ 60}h ${sleepMinutesToday % 60}m'
        : '${sleepMinutesToday}m';

      // Format last feed
      String lastFeedStr = 'No feeds yet';
      if (lastFeed != null) {
        final diff = now.difference(lastFeed);
        if (diff.inMinutes < 60) {
          lastFeedStr = '${diff.inMinutes}m ago';
        } else {
          lastFeedStr = '${diff.inHours}h ${diff.inMinutes % 60}m ago';
        }
      }

      // Save data
      await HomeWidget.saveWidgetData<String>('sleep_today', sleepStr);
      await HomeWidget.saveWidgetData<String>('last_feed', lastFeedStr);

      // Trigger native widget update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'BabyCornWidget',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
