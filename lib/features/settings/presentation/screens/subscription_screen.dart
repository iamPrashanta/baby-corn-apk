// // lib/features/settings/presentation/screens/subscription_screen.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../core/design/tokens/colors.dart';
// import '../../../../core/widgets/safe_scrollable_wrapper.dart';
// import '../providers/premium_provider.dart';

// class SubscriptionScreen extends ConsumerWidget {
//   const SubscriptionScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final isPremium = ref.watch(premiumProvider);

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: isDark
//                 ? [const Color(0xFF1E1E2C), const Color(0xFF121212)]
//                 : [Colors.blue.shade50, Colors.white],
//           ),
//         ),
//         child: SafeScrollableWrapper(
//           child: Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Icon Header
//                 Center(
//                   child: Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.workspace_premium,
//                       size: 80,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Titles
//                 const Text(
//                   'Baby Corn Premium',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   isPremium
//                       ? 'You are already a Pro member.'
//                       : 'Smarter parenting. Better tracking. Secure backup.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: isPremium ? Colors.green : Colors.grey,
//                     fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//                 const SizedBox(height: 48),

//                 // Features List
//                 _buildFeatureRow(
//                   icon: Icons.cloud_sync,
//                   title: 'Unlimited Cloud Backup',
//                   description: 'Secure Google Cloud Storage.',
//                   isDark: isDark,
//                 ),
//                 const SizedBox(height: 20),
//                 _buildFeatureRow(
//                   icon: Icons.devices,
//                   title: 'Cross Device Restore',
//                   description: 'Restore your baby data safely across devices.',
//                   isDark: isDark,
//                 ),
//                 const SizedBox(height: 20),
//                 _buildFeatureRow(
//                   icon: Icons.insights,
//                   title: 'Advanced Statistics & Insights',
//                   description: 'Detailed charts and health reports.',
//                   isDark: isDark,
//                 ),
//                 const SizedBox(height: 20),
//                 _buildFeatureRow(
//                   icon: Icons.auto_awesome,
//                   title: 'Future AI Parenting Features',
//                   description: 'Priority feature access and AI tools.',
//                   isDark: isDark,
//                 ),

//                 const Spacer(),

//                 // Pricing Card
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).cardColor,
//                     borderRadius: BorderRadius.circular(4.0),
//                     border: Border.all(
//                         color: AppColors.primary.withOpacity(0.5), width: 2),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.primary.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Monthly Plan',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: isDark
//                                   ? Colors.white70
//                                   : Colors.grey.shade800,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           const Text(
//                             '₹99 / month',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w900,
//                               color: AppColors.primary,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: AppColors.primary.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(4.0),
//                         ),
//                         child: const Text(
//                           'Most Popular',
//                           style: TextStyle(
//                             color: AppColors.primary,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // Subscribe / Manage Button
//                 ElevatedButton(
//                   onPressed: () {
//                     if (isPremium) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text(
//                                 'Manage subscriptions via Google Play Store or App Store.')),
//                       );
//                     } else {
//                       ref.read(premiumProvider.notifier).buyPremium();
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         isPremium ? Colors.grey.shade800 : AppColors.primary,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 20),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(4.0),
//                     ),
//                     elevation: 5,
//                   ),
//                   child: Text(
//                     isPremium ? 'Manage Subscription' : 'Start Premium',
//                     style: const TextStyle(
//                         fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 if (!isPremium)
//                   TextButton(
//                     onPressed: () {
//                       ref.read(premiumProvider.notifier).restorePurchases();
//                     },
//                     child: const Text('Restore Purchases'),
//                   ),
//                 const SizedBox(height: 16),
//                 Text(
//                   isPremium
//                       ? 'Your subscription is active.'
//                       : 'Your data remains yours.\nStored securely using Firebase.\nSubscriptions handled by Google Play.\nCancel anytime.',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 24),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureRow({
//     required IconData icon,
//     required String title,
//     required String description,
//     required bool isDark,
//   }) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppColors.primary.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: AppColors.primary, size: 24),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 description,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: isDark ? Colors.white70 : Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
