// features/auth/data/repositories/baby_repository.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/baby_model.dart';

final babyRepositoryProvider = Provider<BabyRepository>((ref) {
  return BabyRepository();
});

class BabyRepository {
  BabyRepository() {
    // Safe migration — box might not be open yet on first provider instantiation
    try {
      _migrateOldData();
    } catch (_) {}
  }

  void _migrateOldData() {
    final box = HiveManager.getSettingsBox();
    final name = box.get('baby_name');
    final birthDateStr = box.get('baby_birthdate');
    final babiesJson = box.get('babies_list');
    
    // If we have old data but no new data, migrate it!
    if (name != null && birthDateStr != null && babiesJson == null) {
      final baby = BabyModel(
        id: const Uuid().v4(),
        name: name,
        birthDate: DateTime.parse(birthDateStr),
        feedingType: box.get('baby_feeding_type') ?? 'Mixed',
        gender: box.get('baby_gender') ?? 'Prefer not to say',
        birthWeight: box.get('baby_birth_weight') ?? 3.2,
      );
      
      saveBabies([baby]);
      setActiveBabyId(baby.id);
      
      // Clear old keys to prevent running migration again
      box.delete('baby_name');
      box.delete('baby_birthdate');
    }
  }

  List<BabyModel> getBabies() {
    final box = HiveManager.getSettingsBox();
    final babiesJson = box.get('babies_list');
    if (babiesJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(babiesJson);
      return decoded.map((e) => BabyModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBabies(List<BabyModel> babies) async {
    final box = HiveManager.getSettingsBox();
    final encoded = jsonEncode(babies.map((e) => e.toJson()).toList());
    await box.put('babies_list', encoded);
  }

  Future<void> addBaby(BabyModel baby) async {
    final babies = getBabies();
    babies.add(baby);
    await saveBabies(babies);
    if (babies.length == 1) {
      await setActiveBabyId(baby.id);
      await HiveManager.getSettingsBox().put('onboarding_complete', true);
    }
  }

  Future<void> updateBaby(BabyModel baby) async {
    final babies = getBabies();
    final index = babies.indexWhere((b) => b.id == baby.id);
    if (index != -1) {
      babies[index] = baby;
      await saveBabies(babies);
    }
  }

  String? getActiveBabyId() {
    final box = HiveManager.getSettingsBox();
    return box.get('active_baby_id') as String?;
  }

  Future<void> setActiveBabyId(String id) async {
    final box = HiveManager.getSettingsBox();
    await box.put('active_baby_id', id);
  }

  bool isOnboardingComplete() {
    final box = HiveManager.getSettingsBox();
    return box.get('onboarding_complete', defaultValue: false) as bool;
  }

  // Legacy wrappers for backward compatibility
  Future<void> saveBabyProfile({
    required String name,
    required DateTime birthDate,
    required String feedingType,
    required String gender,
    required double birthWeight,
  }) async {
    final baby = BabyModel(
      id: const Uuid().v4(),
      name: name,
      birthDate: birthDate,
      feedingType: feedingType,
      gender: gender,
      birthWeight: birthWeight,
    );
    await addBaby(baby);
  }

  Map<String, dynamic>? getBabyProfile() {
    final activeId = getActiveBabyId();
    if (activeId == null) return null;
    final babies = getBabies();
    try {
      final baby = babies.firstWhere((b) => b.id == activeId);
      return {
        'name': baby.name,
        'birthDate': baby.birthDate,
        'feedingType': baby.feedingType,
        'gender': baby.gender,
        'birthWeight': baby.birthWeight,
      };
    } catch (e) {
      return null;
    }
  }
}
