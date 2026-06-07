// lib/features/medication/data/repositories/medication_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/medication_model.dart';
import '../../../../core/local_storage/hive_manager.dart';
import 'package:flutter/foundation.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

class MedicationRepository {
  // Medications
  Future<void> saveMedication(MedicationModel medication) async {
    final box = HiveManager.getMedicationsBox();
    await box.put(medication.id, medication);
    debugPrint('[MEDICATION SAVE] Saved locally: ${medication.name}');
  }

  Future<void> updateMedication(MedicationModel medication) async {
    final box = HiveManager.getMedicationsBox();
    await box.put(medication.id, medication);
    debugPrint('[MEDICATION SAVE] Updated locally: ${medication.name}');
  }

  Future<void> deleteMedication(String id) async {
    final box = HiveManager.getMedicationsBox();
    await box.delete(id);
  }

  List<MedicationModel> getAllMedications() {
    final box = HiveManager.getMedicationsBox();
    final meds = box.values.toList();
    if (meds.isNotEmpty) {
      debugPrint(
          '[MEDICATION LOAD] Loaded ${meds.length} medications from local storage');
    }
    return meds;
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
