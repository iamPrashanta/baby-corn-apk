// features/settings/presentation/screens/edit_baby_screen.dart

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/domain/models/baby_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import '../../../../core/constants/app_colors.dart';

class EditBabyScreen extends ConsumerStatefulWidget {
  final BabyModel baby;
  const EditBabyScreen({super.key, required this.baby});

  @override
  ConsumerState<EditBabyScreen> createState() => _EditBabyScreenState();
}

class _EditBabyScreenState extends ConsumerState<EditBabyScreen> {
  late final TextEditingController _nameController;
  late DateTime _birthDate;
  late String _gender;
  late double _birthWeight;
  late double? _birthHeight;
  bool _isHeightInCm = true;
  late String _feedingType;
  late String _avatarEmoji;

  bool _isSaving = false;


  static const List<Map<String, dynamic>> _genderOptions = [
    {'label': 'Girl', 'icon': Icons.face_3, 'color': Color(0xFFFFD8D3)},
    {'label': 'Boy', 'icon': Icons.face_6, 'color': Color(0xFFD4E6F1)},
    {'label': 'Prefer not to say', 'icon': Icons.favorite_border, 'color': Color(0xFFFFF5D1)},
  ];

  static const List<Map<String, dynamic>> _feedingOptions = [
    {'label': 'Breastmilk', 'icon': Icons.water_drop_outlined, 'color': Color(0xFFFFE5B4)},
    {'label': 'Formula', 'icon': Icons.local_drink_outlined, 'color': Color(0xFFD4E6F1)},
    {'label': 'Mixed', 'icon': Icons.set_meal_outlined, 'color': Color(0xFFE2D5F8)},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.baby.name);
    _birthDate = widget.baby.birthDate;
    _gender = widget.baby.gender;
    _birthWeight = widget.baby.birthWeight;
    _birthHeight = widget.baby.birthHeight ?? 50.0;
    _feedingType = widget.baby.feedingType;
    _avatarEmoji = widget.baby.avatarEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = widget.baby.copyWith(
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      birthWeight: _birthWeight,
      birthHeight: _birthHeight,
      feedingType: _feedingType,
      avatarEmoji: _avatarEmoji,
    );

    await ref.read(activeBabyProvider.notifier).updateBaby(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updated.name}\'s profile updated ✓'),
          backgroundColor: AppColors.primary.withOpacity(0.9),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1C20) : Colors.white;
    final sectionLabelColor = isDark ? Colors.white54 : const Color(0xFF9A8C98);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Baby'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Avatar picker ─────────────────────────────────────
          _buildSection(
            context,
            label: 'AVATAR',
            labelColor: sectionLabelColor,
            child: _buildAvatarPicker(cardBg, isDark),
          ),
          const SizedBox(height: 24),

          // ── Name ──────────────────────────────────────────────
          _buildSection(
            context,
            label: 'NAME',
            labelColor: sectionLabelColor,
            child: _buildNameField(cardBg, isDark),
          ),
          const SizedBox(height: 24),

          // ── Birth Date ────────────────────────────────────────
          _buildSection(
            context,
            label: 'BIRTH DATE',
            labelColor: sectionLabelColor,
            child: _buildBirthDateTile(cardBg, isDark),
          ),
          const SizedBox(height: 24),

          // ── Gender ────────────────────────────────────────────
          _buildSection(
            context,
            label: 'GENDER',
            labelColor: sectionLabelColor,
            child: _buildChoiceGroup(
              options: _genderOptions,
              selected: _gender,
              cardBg: cardBg,
              onSelect: (val) => setState(() => _gender = val),
            ),
          ),
          const SizedBox(height: 24),

          // ── Birth Weight ──────────────────────────────────────
          _buildSection(
            context,
            label: 'BIRTH WEIGHT',
            labelColor: sectionLabelColor,
            child: _buildWeightSlider(cardBg, isDark),
          ),
          const SizedBox(height: 24),

          // ── Birth Height ──────────────────────────────────────
          _buildSection(
            context,
            label: 'BIRTH HEIGHT',
            labelColor: sectionLabelColor,
            child: _buildHeightSlider(cardBg, isDark),
          ),
          const SizedBox(height: 24),

          // ── Feeding Type ──────────────────────────────────────
          _buildSection(
            context,
            label: 'FEEDING TYPE',
            labelColor: sectionLabelColor,
            child: _buildChoiceGroup(
              options: _feedingOptions,
              selected: _feedingType,
              cardBg: cardBg,
              onSelect: (val) => setState(() => _feedingType = val),
            ),
          ),
          const SizedBox(height: 40),

          // ── Save Button ───────────────────────────────────────
          _buildSaveButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Section wrapper ──────────────────────────────────────────────────────

  Widget _buildSection(BuildContext context, {
    required String label,
    required Color labelColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Avatar picker ────────────────────────────────────────────────────────

  Widget _buildAvatarPicker(Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Current avatar preview / input
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: TextField(
                textAlign: TextAlign.center,
                maxLength: 2,
                style: const TextStyle(fontSize: 40),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: "",
                  contentPadding: EdgeInsets.zero,
                ),
                controller: TextEditingController(text: _avatarEmoji)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _avatarEmoji.length),
                  ),
                onChanged: (val) {
                  if (val.isNotEmpty) {
                    _avatarEmoji = val;
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap the emoji above to pick your own!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Name field ───────────────────────────────────────────────────────────

  Widget _buildNameField(Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Baby Name',
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.black26,
            fontWeight: FontWeight.normal,
            fontSize: 22,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Birth date tile ──────────────────────────────────────────────────────

  Widget _buildBirthDateTile(Color cardBg, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _birthDate,
          firstDate: DateTime(2018),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _birthDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: Color(0xFFFFB2A6), size: 28),
            const SizedBox(width: 16),
            Text(
              '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Icon(
              Icons.edit_calendar_outlined,
              size: 20,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Choice group (gender / feeding) ─────────────────────────────────────

  Widget _buildChoiceGroup({
    required List<Map<String, dynamic>> options,
    required String selected,
    required Color cardBg,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          final label = opt['label'] as String;
          final icon = opt['icon'] as IconData;
          final color = opt['color'] as Color;
          final isSelected = selected == label;
          final isLast = i == options.length - 1;

          return GestureDetector(
            onTap: () => onSelect(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.fromLTRB(12, i == 0 ? 12 : 0, 12, isLast ? 12 : 6),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 26, color: isSelected ? color.withOpacity(0.85) : Colors.grey),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: color, size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Weight Slider ────────────────────────────────────────────────────────

  Widget _buildWeightSlider(Color cardBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text(
                '${_birthWeight.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: _birthWeight,
              min: 1.0,
              max: 10.0,
              divisions: 90, // increments of 0.1 kg
              onChanged: (val) {
                setState(() => _birthWeight = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Height Slider ────────────────────────────────────────────────────────

  Widget _buildHeightSlider(Color cardBg, bool isDark) {
    // If not in cm, we show inches
    final displayValue = _isHeightInCm ? _birthHeight! : _birthHeight! * 0.393701;
    final displayUnit = _isHeightInCm ? 'cm' : 'in';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Height', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Text(
                    '${displayValue.toStringAsFixed(1)} $displayUnit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, label: Text('cm')),
                      ButtonSegment(value: false, label: Text('in')),
                    ],
                    selected: {_isHeightInCm},
                    onSelectionChanged: (val) {
                      setState(() => _isHeightInCm = val.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary.withOpacity(0.2);
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: _birthHeight!,
              min: 30.0,
              max: 100.0,
              divisions: 70, // increments of 1 cm
              onChanged: (val) {
                setState(() => _birthHeight = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Save button ──────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
