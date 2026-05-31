// lib/features/medication/data/repositories/medication_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medication_model.dart';
import '../../domain/models/medication_log_model.dart';
import '../../../../core/local_storage/hive_manager.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

class MedicationRepository {
  // Medications
  Future<void> saveMedication(MedicationModel medication) async {
    final box = HiveManager.getMedicationsBox();
    await box.put(medication.id, medication);
  }

  Future<void> updateMedication(MedicationModel medication) async {
    final box = HiveManager.getMedicationsBox();
    await box.put(medication.id, medication);
  }

  Future<void> deleteMedication(String id) async {
    final box = HiveManager.getMedicationsBox();
    await box.delete(id);
  }

  List<MedicationModel> getAllMedications() {
    final box = HiveManager.getMedicationsBox();
    return box.values.toList();
  }

  // Medication Logs
  Future<void> saveMedicationLog(MedicationLogModel log) async {
    final box = HiveManager.getMedicationLogsBox();
    await box.put(log.id, log);
  }

  Future<void> updateMedicationLog(MedicationLogModel log) async {
    final box = HiveManager.getMedicationLogsBox();
    await box.put(log.id, log);
  }

  Future<void> deleteMedicationLog(String id) async {
    final box = HiveManager.getMedicationLogsBox();
    await box.delete(id);
  }

  List<MedicationLogModel> getAllMedicationLogs() {
    final box = HiveManager.getMedicationLogsBox();
    return box.values.toList();
  }

  List<MedicationLogModel> getLogsForMedication(String medicationId) {
    final box = HiveManager.getMedicationLogsBox();
    return box.values.where((log) => log.medicationId == medicationId).toList();
  }

  // PDF Export Ready (Stubs)
  Future<String> generateDoctorReport(String babyId) async {
    // TODO: Implement PDF generation using pdf package
    // Extract medication adherence, missed doses, and history.
    return "path/to/generated/report.pdf";
  }

  Map<String, dynamic> getAdherenceStats(String babyId) {
    // TODO: Calculate adherence % based on taken vs missed logs
    return {
      'adherencePercentage': 0.0,
      'totalMissed': 0,
      'totalTaken': 0,
    };
  }
}
