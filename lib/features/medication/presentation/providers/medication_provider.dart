import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medication_model.dart';
import '../../domain/models/medication_log_model.dart';
import '../../data/repositories/medication_repository.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

final medicationsProvider = StateNotifierProvider<MedicationsNotifier,
    AsyncValue<List<MedicationModel>>>((ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  final activeBaby = ref.watch(activeBabyProvider);
  return MedicationsNotifier(repository, activeBaby?.id);
});

class MedicationsNotifier
    extends StateNotifier<AsyncValue<List<MedicationModel>>> {
  final MedicationRepository _repository;
  final String? _activeBabyId;

  MedicationsNotifier(this._repository, this._activeBabyId)
      : super(const AsyncValue.loading()) {
    loadMedications();
  }

  void loadMedications() {
    try {
      final allMeds = _repository.getAllMedications();
      final filtered = allMeds.where((m) => m.babyId == _activeBabyId).toList();
      filtered
          .sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first

      // Auto-detect missed doses
      _checkMissedDoses(filtered);

      state = AsyncValue.data(filtered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _checkMissedDoses(List<MedicationModel> meds) {
    final now = DateTime.now();
    for (final med in meds) {
      if (!med.isActive) continue;

      final logs = _repository.getLogsForMedication(med.id);

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

        final scheduledTime =
            DateTime(now.year, now.month, now.day, hour, minute);

        // If it's more than 30 mins past scheduled time and no log exists for this time
        if (now.difference(scheduledTime).inMinutes > 30) {
          final hasLog = logs.any((log) =>
              log.scheduledTime.year == scheduledTime.year &&
              log.scheduledTime.month == scheduledTime.month &&
              log.scheduledTime.day == scheduledTime.day &&
              log.scheduledTime.hour == scheduledTime.hour &&
              log.scheduledTime.minute == scheduledTime.minute);

          if (!hasLog) {
            // Create a missed log automatically
            final missedLog = MedicationLogModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              medicationId: med.id,
              scheduledTime: scheduledTime,
              status: 'missed',
              note: 'Auto-detected as missed',
            );
            _repository.saveMedicationLog(missedLog);
          }
        }
      }
    }
  }

  Future<void> takeDose(MedicationModel medication,
      {String takenBy = 'Caregiver'}) async {
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

      final log = MedicationLogModel(
        id: now.millisecondsSinceEpoch.toString(),
        medicationId: medication.id,
        scheduledTime: closestSchedule,
        actualTime: now,
        status: 'taken',
        takenBy: takenBy,
      );

      await _repository.saveMedicationLog(log);

      // Reduce stock
      final updatedMed = medication.copyWith(
        remainingQuantity:
            (medication.remainingQuantity - medication.doseAmount) >= 0
                ? (medication.remainingQuantity - medication.doseAmount)
                : 0,
      );
      await _repository.updateMedication(updatedMed);

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
    AsyncValue<List<MedicationLogModel>>,
    String>((ref, medicationId) {
  final repository = ref.watch(medicationRepositoryProvider);
  return MedicationLogsNotifier(repository, medicationId);
});

class MedicationLogsNotifier
    extends StateNotifier<AsyncValue<List<MedicationLogModel>>> {
  final MedicationRepository _repository;
  final String _medicationId;

  MedicationLogsNotifier(this._repository, this._medicationId)
      : super(const AsyncValue.loading()) {
    loadLogs();
  }

  void loadLogs() {
    try {
      final logs = _repository.getLogsForMedication(_medicationId);
      logs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(MedicationLogModel log) async {
    try {
      await _repository.saveMedicationLog(log);
      loadLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLog(MedicationLogModel log) async {
    try {
      await _repository.updateMedicationLog(log);
      loadLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
