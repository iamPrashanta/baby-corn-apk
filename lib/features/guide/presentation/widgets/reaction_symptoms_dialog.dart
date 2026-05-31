import 'package:flutter/material.dart';
import '../../../../core/theme/glass_system/glass_colors.dart';

class ReactionSymptomsDialog extends StatefulWidget {
  const ReactionSymptomsDialog({super.key});

  @override
  State<ReactionSymptomsDialog> createState() => _ReactionSymptomsDialogState();
}

class _ReactionSymptomsDialogState extends State<ReactionSymptomsDialog> {
  final List<String> _options = [
    "Rash / Hives",
    "Vomiting",
    "Diarrhea",
    "Swelling",
    "Breathing Difficulty",
    "Other",
  ];
  final Set<String> _selected = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _doctorNoteController = TextEditingController();
  bool _markAsAvoid = false;

  @override
  void dispose() {
    _notesController.dispose();
    _doctorNoteController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selected.isEmpty && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom or add notes.')),
      );
      return;
    }
    
    final symptoms = _selected.toList();
    if (_selected.contains("Other") && _notesController.text.trim().isNotEmpty) {
      symptoms.add("Notes: ${_notesController.text.trim()}");
    }

    Navigator.of(context).pop({
      'symptoms': symptoms,
      'doctorNote': _doctorNoteController.text.trim().isEmpty ? null : _doctorNoteController.text.trim(),
      'markAsAvoid': _markAsAvoid,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? GlassColors.darkGlassSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Log Reaction",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Select observed symptoms:",
                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map((option) {
                  final isSelected = _selected.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(option);
                        } else {
                          _selected.remove(option);
                        }
                      });
                    },
                    selectedColor: Colors.red.withOpacity(0.2),
                    checkmarkColor: Colors.red,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.red.shade700 : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              if (_selected.contains("Other")) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: "Additional Notes",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                "Medical Advice (Optional)",
                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _doctorNoteController,
                decoration: InputDecoration(
                  labelText: "Doctor's Recommendation (e.g. Avoid until 12m)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Never Introduce Again"),
                subtitle: const Text("Mark this food as 'Avoid'"),
                value: _markAsAvoid,
                activeColor: Colors.red,
                onChanged: (val) {
                  setState(() {
                    _markAsAvoid = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save Record"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
