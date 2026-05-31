// lib/features/auth/data/repositories/baby_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      _migrateOldData(); // Run async without awaiting in constructor
    } catch (_) {}
  }

  Future<void> _migrateOldData() async {
    final settingsBox = HiveManager.getSettingsBox();
    final profileBox = HiveManager.getProfileBox();

    // 1. Migrate legacy version 1 (individual keys) to babies_list in profileBox
    final name = settingsBox.get('baby_name');
    final birthDateStr = settingsBox.get('baby_birthdate');
    final babiesJsonLegacy = settingsBox
        .get('babies_list'); // checking settingsBox for version 2 data

    // If we have old v1 data, migrate it!
    if (name != null &&
        birthDateStr != null &&
        babiesJsonLegacy == null &&
        profileBox.get('babies_list') == null) {
      final baby = BabyModel(
        id: const Uuid().v4(),
        name: name,
        birthDate: DateTime.parse(birthDateStr),
        feedingType: settingsBox.get('baby_feeding_type') ?? 'Mixed',
        gender: settingsBox.get('baby_gender') ?? 'Prefer not to say',
        birthWeight: settingsBox.get('baby_birth_weight') ?? 3.2,
      );

      await saveBabies([baby]);
      await setActiveBabyId(baby.id);

      // Clear old v1 keys
      await settingsBox.delete('baby_name');
      await settingsBox.delete('baby_birthdate');
    }

    // 2. Migrate from settingsBox to profileBox safely
    if (settingsBox.containsKey('babies_list')) {
      if (!profileBox.containsKey('babies_list')) {
        await profileBox.put('babies_list', settingsBox.get('babies_list'));
      }
      await settingsBox.delete('babies_list');
    }
    
    if (settingsBox.containsKey('active_baby_id')) {
      if (!profileBox.containsKey('active_baby_id')) {
        await profileBox.put('active_baby_id', settingsBox.get('active_baby_id'));
      }
      await settingsBox.delete('active_baby_id');
    }
  }

  List<BabyModel> getBabies() {
    final box = HiveManager.getProfileBox();
    final babiesJson = box.get('babies_list');
    if (babiesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(babiesJson);
      return decoded.map((e) => BabyModel.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint("ERROR PARSING BABIES: $e\n$st");
      return [];
    }
  }

  Future<void> saveBabies(List<BabyModel> babies) async {
    final box = HiveManager.getProfileBox();
    final encoded = jsonEncode(babies.map((e) => e.toJson()).toList());
    await box.put('babies_list', encoded);
  }

  Future<void> addBaby(BabyModel baby) async {
    final babies = getBabies();
    babies.add(baby);
    await saveBabies(babies);
    if (babies.length == 1) {
      await setActiveBabyId(baby.id);
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

  Future<void> deleteBaby(String id) async {
    final babies = getBabies();
    babies.removeWhere((b) => b.id == id);
    await saveBabies(babies);

    // If the active baby was deleted, switch to another one if available
    if (getActiveBabyId() == id) {
      if (babies.isNotEmpty) {
        await setActiveBabyId(babies.first.id);
      } else {
        final box = HiveManager.getProfileBox();
        await box.delete('active_baby_id');
      }
    }
  }

  String? getActiveBabyId() {
    final box = HiveManager.getProfileBox();
    var id = box.get('active_baby_id') as String?;
    
    // Active Baby Self-Heal
    if (id == null) {
      final babies = getBabies();
      if (babies.isNotEmpty) {
        id = babies.first.id;
        box.put('active_baby_id', id); // Self-heal active baby synchronously
      }
    }
    return id;
  }

  Future<void> setActiveBabyId(String id) async {
    final box = HiveManager.getProfileBox();
    await box.put('active_baby_id', id);
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
