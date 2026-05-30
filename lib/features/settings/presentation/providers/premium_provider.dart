// features/settings/presentation/providers/premium_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumNotifier extends StateNotifier<bool> {
  // Default to false (Not a Pro user)
  PremiumNotifier() : super(false);

  void unlockPremium() {
    state = true;
  }
  
  void resetPremium() {
    state = false;
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
