import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medication_model.dart';
import '../../data/repositories/medication_repository.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../records/data/repositories/local_record_repository.dart';
import '../../../records/domain/models/record_model.dart';
import '../../../records/presentation/providers/records_provider.dart';

final medicationsProvider = StateNotifierProvider<MedicationsNotifier, AsyncValue<List<MedicationModel>>>((ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  final recordRepository = ref.watch(localRecordRepositoryProvider);
  final activeBaby = ref.watch(activeBabyProvider);
  
  // Also watch records to trigger a rebuild when a log is added so `_checkMissedDoses` gets latest
  ref.watch(recordsProvider);

  return MedicationsNotifier(repository, recordRepository, activeBaby?.id);
});

class MedicationsNotifier extends StateNotifier<AsyncValue<List<MedicationModel>>> {
  final MedicationRepository _repository;
  final LocalRecordRepository _recordRepository;
  final String? _activeBabyId;

  MedicationsNotifier(this._repository, this._recordRepository, this._activeBabyId)
      : super(const AsyncValue.loading()) {
    loadMedications();
  }

  void loadMedications() {
    try {
      final allMeds = _repository.getAllMedications();
      final filtered = allMeds.where((m) => m.babyId == _activeBabyId).toList();
      filtered.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first

      // Auto-detect missed doses
      _checkMissedDoses(filtered);

      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<RecordModel> _getLogsForMedication(String medicationId) {
    return _recordRepository.getAllRecords()
        .where((r) => r.type == 'medication' && r.metadata['medicationId'] == medicationId)
        .toList();
  }

  void _checkMissedDoses(List<MedicationModel> meds) {
    final now = DateTime.now();
    for (final med in meds) {
      if (!med.isActive) continue;

      final logs = _getLogsForMedication(med.id);

      for (final timeStr in med.times) {
        final parts = timeStr.split(' ');
        if (parts.length != 2) continue;
        final timeParts = parts[0].split(':');
        int hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        if (parts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }

        final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

        // If it's more than 30 mins past scheduled time and no log exists for this time
        if (now.difference(scheduledTime).inMinutes > 30) {
          final hasLog = logs.any((log) {
            final stStr = log.metadata['scheduledTime'];
            if (stStr == null) return false;
            final st = DateTime.parse(stStr);
            return st.year == scheduledTime.year &&
                st.month == scheduledTime.month &&
                st.day == scheduledTime.day &&
                st.hour == scheduledTime.hour &&
                st.minute == scheduledTime.minute;
          });

          if (!hasLog) {
            // Create a missed log automatically
            final missedLog = RecordModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'medication',
              timestamp: scheduledTime,
              metadata: {
                'babyId': _activeBabyId,
                'medicationId': med.id,
                'medicationName': med.name,
                'status': 'missed',
                'scheduledTime': scheduledTime.toIso8601String(),
                'note': 'Auto-detected as missed',
              },
            );
            _recordRepository.saveRecord(missedLog);
          }
        }
      }
    }
  }

  Future<String?> takeDose(MedicationModel medication, {String takenBy = 'Caregiver', DateTime? actualTime}) async {
    try {
      final now = DateTime.now();

      // Find the closest scheduled time for today
      DateTime closestSchedule = now;
      int minDiff = 24 * 60; // Max diff in mins

      for (final timeStr in medication.times) {
        final parts = timeStr.split(' ');
        if (parts.length != 2) continue;
        final timeParts = parts[0].split(':');
        int hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        if (parts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }

        final sTime = DateTime(now.year, now.month, now.day, hour, minute);
        final diff = (now.difference(sTime).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestSchedule = sTime;
        }
      }

      final doseTime = actualTime ?? now;
      final logId = now.millisecondsSinceEpoch.toString();

      final log = RecordModel(
        id: logId,
        type: 'medication',
        timestamp: doseTime,
        metadata: {
          'babyId': _activeBabyId,
          'medicationId': medication.id,
          'medicationName': medication.name,
          'scheduledTime': closestSchedule.toIso8601String(),
          'takenTime': doseTime.toIso8601String(),
          'status': 'taken',
          'takenBy': takenBy,
        },
      );

      await _recordRepository.saveRecord(log);

      // Reduce stock
      final updatedMed = medication.copyWith(
        remainingQuantity:
            (medication.remainingQuantity - medication.doseAmount) >= 0
                ? (medication.remainingQuantity - medication.doseAmount)
                : 0,
      );
      await _repository.updateMedication(updatedMed);

      loadMedications();
      return logId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> undoDose(MedicationModel medication, String logId) async {
    try {
      // 1. Delete the log
      await _recordRepository.deleteRecord(logId);

      // 2. Restore stock
      final restoredMed = medication.copyWith(
        remainingQuantity: medication.remainingQuantity + medication.doseAmount,
      );
      await _repository.updateMedication(restoredMed);

      loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> missDose(MedicationModel medication) async {
    try {
      final now = DateTime.now();

      DateTime closestSchedule = now;
      int minDiff = 24 * 60; 

      for (final timeStr in medication.times) {
        final parts = timeStr.split(' ');
        if (parts.length != 2) continue;
        final timeParts = parts[0].split(':');
        int hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
        if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;

        final sTime = DateTime(now.year, now.month, now.day, hour, minute);
        final diff = (now.difference(sTime).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestSchedule = sTime;
        }
      }

      final log = RecordModel(
        id: now.millisecondsSinceEpoch.toString(),
        type: 'medication',
        timestamp: now,
        metadata: {
          'babyId': _activeBabyId,
          'medicationId': medication.id,
          'medicationName': medication.name,
          'scheduledTime': closestSchedule.toIso8601String(),
          'status': 'missed',
          'note': 'Manually marked as missed',
        },
      );

      await _recordRepository.saveRecord(log);
      loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMedication(MedicationModel medication) async {
    try {
      await _repository.saveMedication(medication);
      loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMedication(MedicationModel medication) async {
    try {
      await _repository.updateMedication(medication);
      loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      await _repository.deleteMedication(id);
      loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Logs Provider
final medicationLogsProvider = StateNotifierProvider.family<
    MedicationLogsNotifier,
    AsyncValue<List<RecordModel>>,
    String>((ref, medicationId) {
  final recordRepository = ref.watch(localRecordRepositoryProvider);
  return MedicationLogsNotifier(recordRepository, medicationId);
});

class MedicationLogsNotifier
    extends StateNotifier<AsyncValue<List<RecordModel>>> {
  final LocalRecordRepository _recordRepository;
  final String _medicationId;

  MedicationLogsNotifier(this._recordRepository, this._medicationId)
      : super(const AsyncValue.loading()) {
    loadLogs();
  }

  void loadLogs() {
    try {
      final logs = _recordRepository.getAllRecords()
          .where((r) => r.type == 'medication' && r.metadata['medicationId'] == _medicationId)
          .toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(RecordModel log) async {
    try {
      await _recordRepository.saveRecord(log);
      loadLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLog(RecordModel log) async {
    try {
      await _recordRepository.updateRecord(log);
      loadLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
