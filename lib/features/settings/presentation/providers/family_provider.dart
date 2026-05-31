import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/family_member_model.dart';
import '../../data/repositories/family_repository.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

final familyProvider = StateNotifierProvider<FamilyNotifier, AsyncValue<List<FamilyMemberModel>>>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  final activeBaby = ref.watch(activeBabyProvider);
  return FamilyNotifier(repository, activeBaby?.id);
});

class FamilyNotifier extends StateNotifier<AsyncValue<List<FamilyMemberModel>>> {
  final FamilyRepository _repository;
  final String? _activeBabyId;

  FamilyNotifier(this._repository, this._activeBabyId) : super(const AsyncValue.loading()) {
    loadMembers();
  }

  void loadMembers() {
    try {
      final allMembers = _repository.getAllMembers();
      final babyMembers = allMembers.where((m) => m.babyId == _activeBabyId).toList();
      babyMembers.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
      
      debugPrint("FamilySharing: Loaded ${babyMembers.length} members for baby $_activeBabyId");
      
      state = AsyncValue.data(babyMembers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> inviteMember({
    required String name,
    required String phoneNumber,
  }) async {
    if (_activeBabyId == null) return;
    
    try {
      // Duplicate Protection
      final allMembers = _repository.getAllMembers();
      final isDuplicate = allMembers.any((m) => 
        m.babyId == _activeBabyId && m.phoneNumber == phoneNumber
      );
      
      if (isDuplicate) {
        throw Exception('A member with this phone number is already invited.');
      }

      final newMember = FamilyMemberModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        babyId: _activeBabyId,
        name: name,
        phoneNumber: phoneNumber,
      );
      
      await _repository.saveMember(newMember);
      debugPrint("FamilySharing: Member saved -> ${newMember.name} (${newMember.phoneNumber})");
      
      loadMembers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeMember(String id) async {
    try {
      await _repository.removeMember(id);
      debugPrint("FamilySharing: Member removed -> ID $id");
      loadMembers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
