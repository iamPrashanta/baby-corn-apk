// features/settings/presentation/providers/premium_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _loadPremiumState();
  }

  void _loadPremiumState() {
    try {
      final box = HiveManager.getSettingsBox();
      state = box.get('is_premium', defaultValue: false);
    } catch (_) {
      state = false;
    }
  }

  void unlockPremium() {
    state = true;
    _savePremiumState(true);
  }
  
  void resetPremium() {
    state = false;
    _savePremiumState(false);
  }

  void _savePremiumState(bool isPremium) {
    try {
      final box = HiveManager.getSettingsBox();
      box.put('is_premium', isPremium);
    } catch (_) {}
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
