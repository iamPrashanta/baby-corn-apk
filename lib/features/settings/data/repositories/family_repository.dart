import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/family_member_model.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

class FamilyRepository {
  List<FamilyMemberModel> getAllMembers() {
    return HiveManager.getFamilyMembersBox().values.toList();
  }

  Future<void> saveMember(FamilyMemberModel member) async {
    await HiveManager.getFamilyMembersBox().put(member.id, member);
  }

  Future<void> removeMember(String id) async {
    await HiveManager.getFamilyMembersBox().delete(id);
  }
}
