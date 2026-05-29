// features/settings/presentation/screens/manage_babies_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/baby_model.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../records/presentation/providers/active_session_provider.dart';

class ManageBabiesScreen extends ConsumerWidget {
  const ManageBabiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBabies = ref.watch(allBabiesProvider);
    final activeBaby = ref.watch(activeBabyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Babies'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allBabies.length,
        itemBuilder: (context, index) {
          final baby = allBabies[index];
          final isActive = baby.id == activeBaby?.id;
          
          return Card(
            elevation: isActive ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.transparent,
                width: 2,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👶', style: TextStyle(fontSize: 24)),
                ),
              ),
              title: Text(
                baby.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                'Born: ${baby.birthDate.day}/${baby.birthDate.month}/${baby.birthDate.year}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    const Icon(Icons.check_circle, color: Colors.green)
                  else
                    TextButton(
                      onPressed: () {
                        final activeSession = ref.read(activeSessionProvider);
                        if (activeSession != null) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Active Timer Running'),
                              content: const Text('You have an active timer running. Please stop or cancel it before switching profiles.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ref.read(activeBabyProvider.notifier).setActiveBaby(baby.id);
                        }
                      },
                      child: const Text('Select'),
                    ),
                  if (allBabies.length > 1) // Only allow deletion if more than 1 baby
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirm(context, ref, baby);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/onboarding?add=true');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Baby'),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, BabyModel baby) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Baby Profile'),
          content: Text('Are you sure you want to delete ${baby.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(activeBabyProvider.notifier).deleteBaby(baby.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
