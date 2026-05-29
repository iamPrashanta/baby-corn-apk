// features/settings/presentation/screens/manage_babies_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/domain/models/baby_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

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
              trailing: isActive
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : TextButton(
                      onPressed: () {
                        ref.read(activeBabyProvider.notifier).setActiveBaby(baby.id);
                      },
                      child: const Text('Select'),
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // For simplicity, we can reuse the onboarding screen or a custom add baby dialog.
          // Since onboarding has all the nice UI, we can just push a simplified Add Baby screen.
          // For now, let's create a quick dialog.
          _showAddBabyDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Baby'),
      ),
    );
  }

  void _showAddBabyDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Baby'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Baby Name',
              hintText: 'Enter name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final baby = BabyModel(
                    id: const Uuid().v4(),
                    name: name,
                    birthDate: DateTime.now(), // default to today
                    feedingType: 'Mixed',
                    gender: 'Prefer not to say',
                    birthWeight: 3.2,
                  );
                  ref.read(activeBabyProvider.notifier).addBaby(baby);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
