// features/records/presentation/providers/active_session_provider.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/active_session_model.dart';
import '../../domain/models/record_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import 'records_provider.dart';

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionModel?>((ref) {
  return ActiveSessionNotifier(ref);
});

class ActiveSessionNotifier extends StateNotifier<ActiveSessionModel?> {
  Timer? _timer;
  final Ref _ref;

  ActiveSessionNotifier(this._ref) : super(null) {
    _loadSession();
  }

  void _loadSession() {
    try {
      final box = HiveManager.getActiveSessionBox();
      if (box.isNotEmpty) {
        final session = box.getAt(0);
        if (session != null) {
          // Validate session integrity
          if (session.startTime.isAfter(DateTime.now())) {
            // Corrupted session — start time in the future, discard
            box.clear();
            return;
          }
          state = session;
          if (session.isRunning) {
            _startTick();
          }
        }
      }
    } catch (e) {
      // If loading fails, start clean
      state = null;
    }
  }

  void startSession(String type,
      {Map<String, dynamic> metadata = const {}}) {
    if (state != null) return; // Don't start if already active

    final activeBaby = _ref.read(activeBabyProvider);
    final mergedMetadata = Map<String, dynamic>.from(metadata);
    if (activeBaby != null) {
      mergedMetadata['babyId'] = activeBaby.id;
    }

    final session = ActiveSessionModel(
      id: const Uuid().v4(),
      type: type,
      startTime: DateTime.now(),
      metadata: mergedMetadata,
    );
    state = session;
    _saveSession(session);
    _startTick();
    HapticFeedback.mediumImpact();
  }

  void pauseSession() {
    if (state != null && state!.isRunning) {
      _timer?.cancel();
      final updated = state!.copyWith(
        isRunning: false,
        pausedAt: DateTime.now(),
      );
      state = updated;
      _saveSession(updated);
      HapticFeedback.lightImpact();
    }
  }

  void resumeSession() {
    if (state != null && !state!.isRunning && state!.pausedAt != null) {
      final pauseDuration =
          DateTime.now().difference(state!.pausedAt!).inSeconds;
      final updated = state!.copyWithClearPaused(
        isRunning: true,
        totalPausedDurationSeconds:
            state!.totalPausedDurationSeconds + pauseDuration,
      );
      state = updated;
      _saveSession(updated);
      _startTick();
      HapticFeedback.lightImpact();
    }
  }

  void updateMetadata(Map<String, dynamic> newMetadata) {
    if (state != null) {
      final mergedMetadata = Map<String, dynamic>.from(state!.metadata)
        ..addAll(newMetadata);
      final updated = state!.copyWith(metadata: mergedMetadata);
      state = updated;
      _saveSession(updated);
    }
  }

  /// Stops the active session, saves a RecordModel to Hive, refreshes providers.
  /// Returns the saved record on success, null on failure.
  Future<RecordModel?> stopAndSaveSession() async {
    if (state == null) return null;

    try {
      _timer?.cancel();
      await FlutterOverlayWindow.closeOverlay();

      // Calculate final duration
      final duration = state!.currentDuration;
      final metadata = Map<String, dynamic>.from(state!.metadata);
      metadata['durationSeconds'] = duration.inSeconds;
      metadata['durationMinutes'] = duration.inMinutes;

      // Normalize type for consistent storage
      final normalizedType = _normalizeType(state!.type);
      
      // Preserve original type info in metadata
      if (normalizedType != state!.type) {
        metadata['originalType'] = state!.type;
      }

      // Create finalized record
      final record = RecordModel(
        id: state!.id,
        type: normalizedType,
        timestamp: state!.startTime,
        metadata: metadata,
      );

      // Atomic save: write record, then clear session
      final recordsBox = HiveManager.getRecordsBox();
      await recordsBox.put(record.id, record);

      // Clear active session
      state = null;
      final sessionBox = HiveManager.getActiveSessionBox();
      await sessionBox.clear();

      // Refresh records provider so dashboard and timeline update immediately
      _ref.invalidate(recordsProvider);

      // Haptic success
      HapticFeedback.mediumImpact();

      return record;
    } catch (e) {
      // If save fails, keep the session alive so data isn't lost
      if (state != null && state!.isRunning) {
        _startTick();
      }
      return null;
    }
  }

  void cancelSession() async {
    _timer?.cancel();
    await FlutterOverlayWindow.closeOverlay();
    state = null;
    final box = HiveManager.getActiveSessionBox();
    await box.clear();
  }

  /// Pauses the ticker (call when app goes to background)
  void pauseTicker() async {
    _timer?.cancel();
    if (state != null && state!.isRunning) {
      if (await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "Baby Corn Timer",
          overlayContent: "Timer running",
          flag: OverlayFlag.defaultFlag,
          alignment: OverlayAlignment.center,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 150,
          width: WindowSize.matchParent,
        );
        FlutterOverlayWindow.shareData({
          'type': 'timer_sync',
          'startTimeMs': state!.startTime.millisecondsSinceEpoch,
        });
      }
    }
  }

  /// Resumes the ticker (call when app comes to foreground)
  void resumeTicker() async {
    await FlutterOverlayWindow.closeOverlay();
    if (state != null && state!.isRunning) {
      _startTick();
    } else if (state != null) {
      // Even if paused, trigger a rebuild to show correct elapsed time
      state = state!.copyWith();
    }
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state != null && state!.isRunning) {
        // Re-assign to trigger UI update — the model's currentDuration 
        // uses DateTime.now() so it's always accurate
        state = state!.copyWith();
      }
    });
  }

  void _saveSession(ActiveSessionModel session) async {
    try {
      final box = HiveManager.getActiveSessionBox();
      if (box.isEmpty) {
        await box.add(session);
      } else {
        await box.putAt(0, session);
      }
    } catch (e) {
      // Fail silently — session is in memory state anyway
    }
  }

  /// Normalizes activity type for consistent storage and display
  String _normalizeType(String type) {
    final lower = type.toLowerCase().trim();
    if (lower.contains('feeding') || lower.contains('feed')) {
      return 'feeding';
    }
    if (lower.contains('sleep')) return 'sleep';
    if (lower.contains('tummy')) return 'tummy_time';
    return lower;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
