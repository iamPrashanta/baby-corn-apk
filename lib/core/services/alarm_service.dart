// lib/core/services/alarm_service.dart
//
// ALARM SYSTEM REBUILD — RC-1, RC-2, RC-3, RC-8
//
// Changes from previous implementation:
//   RC-2/3: Replaced deprecated Alarm.ringStream (StreamController, no replay)
//            with Alarm.ringing (BehaviorSubject, replays current value to new
//            subscribers). Added _pendingAlarmSettings queue + _tryNavigate()
//            with addPostFrameCallback fallback. Added checkPendingAlarm() for
//            MainScaffold and main.dart post-frame hooks.
//   RC-1:   Replaced content:// URI passthrough with a safe _resolveAudioPath()
//            that applies the fallback hierarchy:
//              1. Valid assets/ path → use as-is
//              2. content:// or unknown → assets/audio/alarm.wav
//              3. assets/audio/alarm.wav missing → null (device default alarm)
//   RC-8:   AlarmSettings.payload now carries the actual reminder type string
//            (e.g. 'alarm|feeding|fallback|0') instead of profile.ringtoneUri.
//           Also: androidStopAlarmOnTermination: false so audio keeps playing
//            even when the app is swiped from recents.

import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../features/reminders/domain/models/alarm_profile_model.dart';
import '../router/app_router.dart';

class AlarmService {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  static bool _initialized = false;

  /// Subscription to `Alarm.ringing` — the canonical BehaviorSubject.
  /// Replaces the deprecated `Alarm.ringStream` StreamController.
  static StreamSubscription<dynamic>? _ringingSubscription;

  /// Holds the most recently received ringing alarm that has not yet been
  /// navigated to. Cleared once navigation succeeds.
  static AlarmSettings? _pendingAlarmSettings;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    if (_initialized) return;

    // Subscribe to Alarm.ringing — a BehaviorSubject<AlarmSet>.
    //
    // Why Alarm.ringing instead of Alarm.ringStream?
    //   • ringStream  = StreamController (no replay). Events fired before
    //     subscription are permanently lost.
    //   • Alarm.ringing = BehaviorSubject (replays the CURRENT value to every
    //     new subscriber immediately). After Alarm.init() → checkAlarm()
    //     repopulates _ringing from SharedPreferences + AlarmService.ringingAlarmIds,
    //     subscribing here gives the current ringing set right away.
    //
    // AlarmSet is a set of currently ringing alarms. We iterate it to find
    // the first ringing alarm for navigation.
    _ringingSubscription = Alarm.ringing.listen((alarmSet) {
      debugPrint(
        '[ALARM RING] ringing stream received ${alarmSet.alarms.length} alarm(s): '
        '${alarmSet.alarms.map((a) => a.id).toList()}',
      );

      if (alarmSet.alarms.isEmpty) return;

      // Take the first ringing alarm for navigation. In practice Baby Corn
      // does not allow alarm overlap (allowAlarmOverlap: false).
      final alarm = alarmSet.alarms.first;
      _pendingAlarmSettings = alarm;
      _tryNavigate();
    });

    _initialized = true;
    debugPrint('[ALARM] AlarmService initialized — listening to Alarm.ringing');
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  /// Attempts to push '/alarm' immediately. If the widget tree is not yet
  /// built (rootNavigatorKey.currentContext == null), schedules a retry
  /// via addPostFrameCallback.
  static void _tryNavigate() {
    final alarm = _pendingAlarmSettings;
    if (alarm == null) return;

    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      // Widget tree is ready — navigate now.
      final payload = alarm.payload ?? alarm.notificationSettings.body;
      debugPrint('[ALARM NAV] Navigating to /alarm with payload: $payload');
      ctx.push('/alarm', extra: payload);
      _pendingAlarmSettings = null;
    } else {
      // Widget tree not ready yet (app just launched from killed state).
      // Schedule for next frame. MainScaffold.initState also calls
      // checkPendingAlarm() as a belt-and-suspenders backup.
      debugPrint('[ALARM NAV] Context not ready — scheduling post-frame retry');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _tryNavigate();
      });
    }
  }

  /// Public hook called by:
  ///   • main.dart (post-frame callback after runApp)
  ///   • MainScaffold.initState (post-frame callback)
  ///
  /// Handles two recovery scenarios:
  ///
  /// Layer 1 — pending queue: If _pendingAlarmSettings was set by the
  ///   ringing stream before the widget tree was ready, navigate now.
  ///
  /// Layer 2 — direct query (Change #2): Even if _pendingAlarmSettings is
  ///   null (e.g., app crashed before Alarm.init() ran, or the stream fired
  ///   before AlarmService.init() subscribed), query Alarm.isRinging()
  ///   directly and navigate if any alarm is ringing.
  static Future<void> checkPendingAlarm() async {
    debugPrint('[ALARM RECOVERY] checkPendingAlarm() called');

    // Layer 1: use pending queue
    if (_pendingAlarmSettings != null) {
      debugPrint(
        '[ALARM RECOVERY] Layer 1 — pending alarm found: ${_pendingAlarmSettings!.id}',
      );
      _tryNavigate();
      return;
    }

    // Layer 2: direct Alarm.getAlarms() + Alarm.isRinging() query
    // Handles: crash-before-Alarm.init(), stream missed, any other gap.
    debugPrint('[ALARM RECOVERY] Layer 2 — querying ringing alarms directly');
    try {
      final alarms = await Alarm.getAlarms();
      debugPrint('[ALARM RECOVERY] Found ${alarms.length} stored alarm(s)');

      for (final alarm in alarms) {
        final ringing = await Alarm.isRinging(alarm.id);
        debugPrint(
          '[ALARM RECOVERY] Alarm ${alarm.id} isRinging=$ringing',
        );
        if (ringing) {
          debugPrint(
            '[ALARM RECOVERY] Layer 2 — found ringing alarm: ${alarm.id}',
          );
          _pendingAlarmSettings = alarm;
          _tryNavigate();
          return; // navigate to first ringing alarm only
        }
      }

      debugPrint('[ALARM RECOVERY] No ringing alarms found');
    } catch (e) {
      debugPrint('[ALARM RECOVERY] Error querying alarms: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Resolves the audio path to use for an alarm.
  ///
  /// Fallback hierarchy (Change #1):
  ///   1. Valid Flutter asset path (starts with 'assets/') → pass through
  ///   2. content:// URI, 'default', empty, or unknown → 'assets/audio/alarm.wav'
  ///   3. If assets/audio/alarm.wav is missing (caught below) → null
  ///      (AlarmService native layer then uses device default alarm)
  ///
  /// Why not pass null directly for content://?
  ///   Passing null triggers AudioService to use RingtoneManager.getDefaultUri(),
  ///   which varies by OEM: Samsung uses "Over The Horizon", Xiaomi uses "Ringer",
  ///   etc. Some are quiet. 'assets/audio/alarm.wav' ensures consistent,
  ///   tested audio on every device.
  static Future<String?> _resolveAudioPath(AlarmProfile profile) async {
    final uri = profile.ringtoneUri;

    // Valid Flutter asset — pass through
    if (uri.startsWith('assets/') && uri.isNotEmpty) {
      debugPrint('[ALARM AUDIO] Using custom asset: $uri');
      return uri;
    }

    // content:// URI or anything else → primary fallback
    if (uri.startsWith('content://')) {
      debugPrint(
        '[ALARM AUDIO FALLBACK] content:// URI not supported by alarm package. '
        'Falling back to assets/audio/alarm.wav. URI was: $uri',
      );
    } else if (uri.isNotEmpty && uri != 'default') {
      debugPrint(
        '[ALARM AUDIO FALLBACK] Unknown ringtone URI format: "$uri". '
        'Falling back to assets/audio/alarm.wav.',
      );
    }

    // Try assets/audio/alarm.wav — if it's missing, fall back to null
    // (device default) so the alarm is never silent.
    try {
      await rootBundle.load('assets/audio/alarm.wav');
      debugPrint('[ALARM AUDIO] Using assets/audio/alarm.wav');
      return 'assets/audio/alarm.wav';
    } catch (_) {
      debugPrint(
        '[ALARM AUDIO FALLBACK] assets/audio/alarm.wav not found in bundle. '
        'Falling back to device default alarm (null).',
      );
      return null; // device default alarm — last resort
    }
  }

  /// Schedules a native exact alarm that fires regardless of app state.
  ///
  /// Key AlarmSettings flags:
  ///   androidFullScreenIntent: true     — shows alarm UI over lock screen
  ///   androidStopAlarmOnTermination: false — audio keeps playing when app is
  ///     swiped from recents (RC-2 fix). Audio only stops when user acts on
  ///     AlarmScreen or taps the notification stop button.
  ///   warningNotificationOnKill: false  — Android already handles this via
  ///     AlarmManager; warning notification is iOS-only.
  ///   payload: the reminder type string — used by AlarmScreen._parsePayload()
  ///     (RC-8 fix: was profile.ringtoneUri which AlarmScreen doesn't read)
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required AlarmProfile profile,
    String? payload,
  }) async {
    final audioPath = await _resolveAudioPath(profile);

    // RC-8: payload is the reminder type string (e.g. 'alarm|feeding|fallback|0')
    // Previously this was profile.ringtoneUri which AlarmScreen._parsePayload()
    // never reads. The audio path is already in assetAudioPath.
    final alarmPayload = payload ?? 'alarm|general|fallback|$id';

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioPath, // RC-1: safe path or null (device default)
      loopAudio: true,
      vibrate: profile.vibrationEnabled,
      notificationSettings: NotificationSettings(
        title: title,
        body: alarmPayload, // notification body also carries payload for redundancy
      ),
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(milliseconds: 3000),
        volumeEnforced: true,
      ),
      androidFullScreenIntent: true,   // wake screen, show over lock screen
      androidStopAlarmOnTermination: false, // RC-2: keep ringing even if swiped
      warningNotificationOnKill: false, // Android doesn't need this (iOS only)
      allowAlarmOverlap: false,
      payload: alarmPayload,           // RC-8: actual type string, not ringtoneUri
    );

    await Alarm.set(alarmSettings: alarmSettings);
    debugPrint(
      '[ALARM CREATED] id=$id | time=$dateTime | audio=$audioPath | payload=$alarmPayload',
    );
  }

  // ---------------------------------------------------------------------------
  // Snooze / Stop
  // ---------------------------------------------------------------------------

  static Future<void> snoozeAlarm(int originalId, AlarmProfile profile) async {
    final snoozeTime = DateTime.now().add(
      Duration(minutes: profile.snoozeMinutes),
    );
    await Alarm.stop(originalId);
    await scheduleAlarm(
      id: originalId,
      dateTime: snoozeTime,
      title: 'Snoozed Alarm',
      profile: profile,
    );
    debugPrint('[ALARM SNOOZED] Alarm $originalId snoozed until $snoozeTime');
  }

  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    _pendingAlarmSettings = null; // clear pending so we don't re-navigate
    debugPrint('[ALARM DISMISSED] Alarm $id stopped.');
  }

  static Future<void> stopAll() async {
    await Alarm.stopAll();
    _pendingAlarmSettings = null;
    debugPrint('[ALARM DISMISSED] All alarms stopped.');
  }

  // ---------------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------------

  static Future<List<AlarmSettings>> getActiveAlarms() async {
    return Alarm.getAlarms();
  }

  /// Disposes the ringing subscription. Called if reminders are
  /// permanently disabled.
  static void dispose() {
    _ringingSubscription?.cancel();
    _ringingSubscription = null;
    _initialized = false;
    _pendingAlarmSettings = null;
  }
}
