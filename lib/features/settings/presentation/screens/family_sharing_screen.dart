import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/design/layouts/custom_app_bar.dart';
import '../../../../core/widgets/liquid_background.dart';
import '../../../../core/widgets/safe_scrollable_wrapper.dart';
import '../providers/family_provider.dart';
import '../../../../core/design/tokens/colors.dart';

class FamilySharingScreen extends ConsumerStatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  ConsumerState<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends ConsumerState<FamilySharingScreen> {
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Family Sharing'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPicking ? null : () => _handleInvite(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Invite Member'),
      ),
      body: LiquidBackground(
        child: SafeScrollableWrapper(
          useIntrinsicHeight: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                
                Text(
                  'Your Family',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                
                familyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Center(child: Text('Error: $err')),
                  data: (members) {
                    if (members.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No family members invited yet. Tap the button below to invite someone!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${member.role} • ${member.name}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          member.phoneNumber,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status: ${member.status}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: member.status == 'Pending' ? AppColors.primary : Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (member.status == 'Pending')
                                    TextButton.icon(
                                      icon: const Icon(Icons.send_rounded, size: 16),
                                      label: const Text('Resend Invite'),
                                      onPressed: () => _handleResendInvite(context, member.phoneNumber),
                                    ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    label: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                                    onPressed: () => _handleRemove(context, ref, member.id, member.name),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                
                SizedBox(height: MediaQuery.of(context).padding.bottom + 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleInvite(BuildContext context, WidgetRef ref) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      // 1. Request Contacts Permission
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required to invite family members.')),
          );
        }
        return;
      }

      // 2. Open Native Contact Picker
      final contact = await FlutterContacts.native.showPicker(properties: {ContactProperty.phone});
      if (contact == null) return; // User canceled

      // 3. Try to get a phone number
      if (contact.phones.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected contact has no phone number.')),
          );
        }
        return;
      }

      final phoneNumber = contact.phones.first.number;
      final contactName = contact.displayName;

      // 4. Save member immediately
      try {
        await ref.read(familyProvider.notifier).inviteMember(
          name: contactName ?? 'Unknown',
          phoneNumber: phoneNumber,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
        return;
      }

      // 5. Show Disclaimer Dialog for SMS
      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Invite $contactName?'),
            content: const Text(
              'The contact has been added to your family group.\n\n'
              'Would you like to send them an SMS invitation now?\n\n'
              'Disclaimer: Standard SMS charges may apply from your network provider.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not Now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Send SMS'),
              ),
            ],
          ),
        );

        // 6. Launch SMS App
        if (confirm == true) {
          final uri = Uri.parse(
              "sms:$phoneNumber?body=Hey! Join me on Baby Corn to manage our baby's profile together. Download it here: https://play.google.com/store/apps/details?id=com.babycorn.app");
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open messaging app.')),
              );
            }
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _handleRemove(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove $name from your family group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(familyProvider.notifier).removeMember(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from family.')),
        );
      }
    }
  }

  Future<void> _handleResendInvite(BuildContext context, String phoneNumber) async {
    final uri = Uri.parse(
        "sms:$phoneNumber?body=Hey! Join me on Baby Corn to manage our baby's profile together. Download it here: https://play.google.com/store/apps/details?id=com.babycorn.app");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open messaging app.')),
        );
      }
    }
  }
}
