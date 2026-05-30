import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/local_storage/secure_storage_manager.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/services/biometric_service.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  const PinScreen({super.key, this.isSetup = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorText = '';
  bool _isLoading = false;
  
  Timer? _lockoutTimer;
  DateTime? _lockoutUntil;
  int _failedAttempts = 0;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSetup) {
      _checkLockoutState();
      _checkAndPromptBiometric();
    }
    // Removed auto-focus to prevent Android 14 Emulator crash with InteractionJankMonitor
  }

  Future<void> _checkAndPromptBiometric() async {
    final isAvailable = await BiometricService.isAvailable();
    if (isAvailable && mounted) {
      setState(() {
        _isBiometricAvailable = true;
      });
      // Small delay for UI to build before showing the prompt
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _promptBiometric();
      });
    }
  }

  Future<void> _promptBiometric() async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      return; // Do not allow biometric if locked out
    }
    final result = await BiometricService.authenticateWithResult(
      reason: 'Unlock Baby Corn with your fingerprint or face',
    );
    if (result.success && mounted) {
      await SecureStorageManager.resetPinFailedAttempts();
      context.go('/home');
    } else if (result.error != null && mounted && result.error != 'Authentication cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _checkLockoutState() async {
    _failedAttempts = await SecureStorageManager.getPinFailedAttempts();
    final lockout = await SecureStorageManager.getPinLockoutUntil();
    
    if (lockout != null && lockout.isAfter(DateTime.now())) {
      setState(() {
        _lockoutUntil = lockout;
      });
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
        final secondsLeft = _lockoutUntil!.difference(DateTime.now()).inSeconds;
        setState(() {
          _errorText = 'Locked. Try again in $secondsLeft seconds.';
        });
      } else {
        setState(() {
          _lockoutUntil = null;
          _errorText = '';
        });
        timer.cancel();
      }
    });
  }

  void _onPinChanged(String value) {
    if (_errorText.isNotEmpty) {
      setState(() { _errorText = ''; });
    }

    if (value.length == 4) {
      if (widget.isSetup) {
        if (!_isConfirming) {
          setState(() {
            _confirmPin = value;
            _isConfirming = true;
            _pinController.clear();
          });
          _pinFocus.requestFocus();
        } else {
          _setupPin(value);
        }
      } else {
        _verifyPin(value);
      }
    }
  }

  Future<void> _verifyPin(String pin) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      return;
    }

    final savedPin = await SecureStorageManager.getPin();
    if (pin == savedPin) {
      await SecureStorageManager.resetPinFailedAttempts();
      if (mounted) context.go('/home');
    } else {
      await SecureStorageManager.incrementPinFailedAttempts();
      _failedAttempts = await SecureStorageManager.getPinFailedAttempts();
      
      if (_failedAttempts >= 5) {
        final lockout = DateTime.now().add(const Duration(seconds: 30));
        await SecureStorageManager.setPinLockoutUntil(lockout);
        setState(() {
          _lockoutUntil = lockout;
          _pinController.clear();
        });
        _startLockoutTimer();
      } else {
        setState(() {
          _errorText = 'Incorrect PIN. Try again. (${5 - _failedAttempts} attempts left)';
          _pinController.clear();
        });
        _pinFocus.requestFocus();
      }
    }
  }

  Future<void> _setupPin(String finalPin) async {
    if (finalPin == _confirmPin) {
      await SecureStorageManager.savePin(finalPin);
      if (mounted) {
        final box = HiveManager.getSettingsBox();
        final isOnboarded = box.get('onboarding_complete', defaultValue: false) as bool;
        if (isOnboarded) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      }
    } else {
      setState(() {
        _errorText = 'PINs do not match. Try again.';
        _pinController.clear();
        _confirmPin = '';
        _isConfirming = false;
      });
      _pinFocus.requestFocus();
    }
  }

  Future<void> _handleForgotPin() async {
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Authentication successful, allow user to set a new PIN
      await SecureStorageManager.resetPinFailedAttempts();
      await SecureStorageManager.savePin(''); // Clear old pin
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity verified. Please set a new PIN.')),
        );
        context.go('/pin_setup');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to verify identity. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetup
        ? (_isConfirming ? 'Confirm your PIN' : 'Create a 4-digit PIN')
        : 'Enter your PIN';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isSetup ? Icons.lock_person_outlined : Icons.lock_outline, 
                  size: 64, 
                  color: Theme.of(context).colorScheme.primary
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isSetup 
                      ? 'This secures your baby\'s data'
                      : 'Welcome back',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                  ),
                ),
                const SizedBox(height: 48),
                
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _pinFocus,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32, 
                      letterSpacing: 24, 
                      fontWeight: FontWeight.bold
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                    ),
                    onChanged: _onPinChanged,
                    enabled: _lockoutUntil == null && !_isLoading,
                  ),
                ),
                
                const SizedBox(height: 24),
                if (_errorText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error, 
                        fontWeight: FontWeight.w500
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  const SizedBox(height: 20),
                  
                const SizedBox(height: 32),
                if (!widget.isSetup) ...[
                  if (_isBiometricAvailable && !_isLoading)
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.fingerprint, size: 56),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: _lockoutUntil == null ? _promptBiometric : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use Biometrics',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  _isLoading 
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: _lockoutUntil == null ? _handleForgotPin : null,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Forgot PIN?'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
