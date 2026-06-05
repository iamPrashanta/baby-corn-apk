// lib/features/settings/presentation/providers/premium_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/local_storage/hive_manager.dart';

const String _kPremiumProductId = 'baby_corn_premium_monthly';

class PremiumNotifier extends StateNotifier<bool> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  PremiumNotifier() : super(false) {
    _loadPremiumState();
    _initBilling();
  }

  void _initBilling() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint('[BILLING ERROR] Stream error: $error');
    });
  }

  void _loadPremiumState() {
    try {
      final box = HiveManager.getSettingsBox();
      state = box.get('is_premium', defaultValue: false);
    } catch (_) {
      state = false;
    }
  }

  Future<void> buyPremium() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[BILLING ERROR] Store is not available');
      return;
    }

    const Set<String> kIds = <String>{_kPremiumProductId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[BILLING ERROR] Product not found');
      return;
    }

    final List<ProductDetails> products = response.productDetails;
    if (products.isEmpty) return;

    final ProductDetails productDetails = products.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // For subscriptions we use buyNonConsumable since it's a recurring sub.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[BILLING] Purchase pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('[BILLING ERROR] Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          
          if (purchaseDetails.productID == _kPremiumProductId) {
             debugPrint('[BILLING SUCCESS] Premium activated!');
             state = true;
             _savePremiumState(true);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
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

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
