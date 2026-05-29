// features/onboarding/presentation/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/repositories/baby_repository.dart';
import '../../../auth/domain/models/baby_model.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/local_storage/secure_storage_manager.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/widgets/bouncing_button.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/baby_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isAddingBaby;
  const OnboardingScreen({super.key, this.isAddingBaby = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8;

  // Form State
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Prefer not to say';
  double _birthWeight = 3.2;
  String _feedingType = 'Breastmilk';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Validate required
    if (_nameController.text.trim().isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out your baby\'s name and birth date.')),
      );
      return;
    }

    final baby = BabyModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      birthDate: _birthDate!,
      feedingType: _feedingType,
      gender: _gender,
      birthWeight: _birthWeight,
    );

    await ref.read(babyRepositoryProvider).addBaby(baby);
    await ref.read(activeBabyProvider.notifier).setActiveBaby(baby.id);

    // ✅ Mark onboarding as complete so the app never shows it again
    await HiveManager.getSettingsBox().put('onboarding_complete', true);

    if (mounted) {
      if (widget.isAddingBaby) {
        context.pop();
        return;
      }
      if (AppConfig.enableFirebaseAuth) {
        final hasPin = await SecureStorageManager.hasPin();
        if (hasPin) {
          context.go('/home');
        } else {
          context.go('/pin_setup');
        }
      } else {
        // Offline mode users don't need a PIN
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -50,
            child: _AnimatedBlob(color: const Color(0xFFFFD8D3).withOpacity(0.3), size: 300),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _AnimatedBlob(color: const Color(0xFFE2D5F8).withOpacity(0.3), size: 350),
          ),
          SafeArea(
            child: Column(
          children: [
            // Top App Bar area with Back button and Progress
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: _prevPage,
                    ),
                    Expanded(
                      child: Center(
                        child: _buildProgressIndicator(),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce validation
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomeStep(),
                  _buildNameStep(),
                  _buildBirthDateStep(),
                  _buildGenderStep(),
                  _buildWeightStep(),
                  _buildFeedingStep(),
                  _buildReminderIntroStep(),
                  _buildPrivacyStep(),
                ],
              ),
            ),
          ],
        ),
      ),
          ],
        ),
      );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalPages - 1, (index) {
        // Skip dot for welcome screen (index 0)
        final actualIndex = index + 1;
        final isActive = _currentPage == actualIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: isActive ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------
  // STEP BUILDERS
  // ---------------------------------------------------------

  Widget _buildWelcomeStep() {
    return _buildStepContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFFFFF0E6),
            child: Text('👶🌽', style: TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to Baby Corn',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Track your baby’s little moments\nwith less stress.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildPrimaryButton('Get Started', _nextPage),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return _buildStepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Text(
            'Tell us about your baby',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Baby Name',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onSubmitted: (_) {
              if (_nameController.text.trim().isNotEmpty) _nextPage();
            },
          ),
          const Spacer(flex: 2),
          _buildPrimaryButton('Continue', () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
              return;
            }
            _nextPage();
          }),
        ],
      ),
    );
  }

  Widget _buildBirthDateStep() {
    return _buildStepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Text(
            'When was your baby born?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: const Color(0xFFFFB2A6), // Warm coral
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _birthDate = date);
                _nextPage(); // Auto advance for smooth UX
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, size: 32, color: Color(0xFFFFB2A6)),
                  const SizedBox(width: 16),
                  Text(
                    _birthDate == null 
                        ? 'Select Date' 
                        : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: _birthDate == null ? FontWeight.normal : FontWeight.bold,
                      color: _birthDate == null ? Colors.grey.shade500 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 2),
          _buildPrimaryButton('Continue', () {
            if (_birthDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a birth date')));
              return;
            }
            _nextPage();
          }),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Text(
            'Tell us about your baby',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always add another baby later.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 40),
          _buildSelectionCard(
            title: 'Girl',
            icon: Icons.face_3,
            color: const Color(0xFFFFD8D3), // Pastel Pink
            isSelected: _gender == 'Girl',
            onTap: () {
              setState(() => _gender = 'Girl');
              Future.delayed(const Duration(milliseconds: 200), _nextPage);
            },
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: 'Boy',
            icon: Icons.face_6,
            color: const Color(0xFFD4E6F1), // Pastel Blue
            isSelected: _gender == 'Boy',
            onTap: () {
              setState(() => _gender = 'Boy');
              Future.delayed(const Duration(milliseconds: 200), _nextPage);
            },
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: 'Prefer not to say',
            icon: Icons.favorite_border,
            color: const Color(0xFFFFF5D1), // Soft Yellow
            isSelected: _gender == 'Prefer not to say',
            onTap: () {
              setState(() => _gender = 'Prefer not to say');
              Future.delayed(const Duration(milliseconds: 200), _nextPage);
            },
          ),
          const Spacer(flex: 2),
          _buildPrimaryButton('Continue', _nextPage),
        ],
      ),
    );
  }

  Widget _buildWeightStep() {
    int currentKg = _birthWeight.floor();
    int currentGrams = ((_birthWeight - currentKg) * 1000).round();
    if (currentKg < 1) currentKg = 1;
    if (currentKg > 10) currentKg = 10;

    return _buildStepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Text(
            'Birth Weight',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this later.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 40),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KG Picker
                SizedBox(
                  width: 80,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: currentKg - 1),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final kg = index + 1;
                        final grams = ((_birthWeight - _birthWeight.floor()) * 1000).round();
                        _birthWeight = kg + (grams / 1000);
                      });
                    },
                    children: List.generate(10, (index) => Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
                  ),
                ),
                const Text('kg', style: TextStyle(fontSize: 20, color: Colors.grey)),
                const SizedBox(width: 24),
                // Grams Picker
                SizedBox(
                  width: 100,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: (currentGrams / 100).round()),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final kg = _birthWeight.floor();
                        final grams = index * 100;
                        _birthWeight = kg + (grams / 1000);
                      });
                    },
                    children: List.generate(10, (index) => Center(child: Text('${index * 100}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))),
                  ),
                ),
                const Text('g', style: TextStyle(fontSize: 20, color: Colors.grey)),
              ],
            ),
          ),
          const Spacer(flex: 2),
          _buildPrimaryButton('Continue', _nextPage),
        ],
      ),
    );
  }

  Widget _buildFeedingStep() {
    return _buildStepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          Text(
            'Primary Feeding Type',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps personalize reminders.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 40),
          _buildSelectionCard(
            title: 'Breastmilk',
            icon: Icons.water_drop_outlined,
            color: const Color(0xFFFFE5B4), // Peach
            isSelected: _feedingType == 'Breastmilk',
            onTap: () {
              setState(() => _feedingType = 'Breastmilk');
              Future.delayed(const Duration(milliseconds: 200), _nextPage);
            },
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: 'Formula',
            icon: Icons.local_drink_outlined,
            color: const Color(0xFFD4E6F1), // Light Blue
            isSelected: _feedingType == 'Formula',
            onTap: () {
              setState(() => _feedingType = 'Formula');
              Future.delayed(const Duration(milliseconds: 200), _nextPage);
            },
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: 'Mixed',
            icon: Icons.set_meal_outlined,
            color: const Color(0xFFE2D5F8), // Soft Purple
            isSelected: _feedingType == 'Mixed',
            onTap: () {
              setState(() => _feedingType = 'Mixed');
              Future.delayed(const Duration(milliseconds: 200), _nextPage);
            },
          ),
          const Spacer(flex: 2),
          _buildPrimaryButton('Continue', _nextPage),
        ],
      ),
    );
  }

  Widget _buildReminderIntroStep() {
    return _buildStepContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB2A6).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 80, color: Color(0xFFFFB2A6)),
          ),
          const SizedBox(height: 40),
          Text(
            'We’ll gently remind you about feeding, sleep, and diaper changes.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildPrimaryButton('Sounds Good', _nextPage),
        ],
      ),
    );
  }

  Widget _buildPrivacyStep() {
    return _buildStepContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFE2D5F8).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, size: 80, color: Color(0xFF9C7CD8)),
          ),
          const SizedBox(height: 40),
          Text(
            'Your data stays with you',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'No account required. Works offline.\nYour baby’s records stay securely on your device.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildPrimaryButton('Secure My App', _nextPage),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // REUSABLE COMPONENTS
  // ---------------------------------------------------------

  Widget _buildStepContainer({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: child
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return BouncingButton(
      onPressed: onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: isSelected ? color.withOpacity(1.0) : Colors.grey),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;
  const _AnimatedBlob({required this.color, required this.size});

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size * 1.2,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.size),
            topRight: Radius.circular(widget.size * 0.8),
            bottomLeft: Radius.circular(widget.size * 0.9),
            bottomRight: Radius.circular(widget.size * 1.1),
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 4.seconds, curve: Curves.easeInOutSine);
  }
}
