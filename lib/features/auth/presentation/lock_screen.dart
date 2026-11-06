import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/safe_back_button.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _enteredPin = '';
  bool _hasError = false;
  String _errorMessage = '';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBiometrics(isManualTap: false);
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.backspace) {
        _onBackspace();
        return true;
      } else if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.escape) {
        _onClear();
        return true;
      } else if (event.character != null && RegExp(r'^[0-9]$').hasMatch(event.character!)) {
        _onDigit(event.character!);
        return true;
      }
    }
    return false;
  }

  Future<void> _checkBiometrics({bool isManualTap = false}) async {
    final settings = ref.read(settingsProvider);
    if (!settings.isBiometricEnabled || _isAuthenticating) return;

    _isAuthenticating = true;
    try {
      final canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) {
        if (isManualTap && mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Biometrics not supported on this device';
          });
        }
        return;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan fingerprint to unlock Shopmate POS',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate && mounted) {
        _unlockApp();
      }
    } on PlatformException catch (e) {
      if (isManualTap && mounted) {
        setState(() {
          _hasError = true;
          if (e.code == 'NotEnrolled') {
            _errorMessage = 'No biometrics enrolled in device settings';
          } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
            _errorMessage = 'Biometrics locked. Please enter PIN.';
          } else {
            _errorMessage = 'Biometric check cancelled. Enter PIN.';
          }
        });
      }
    } catch (_) {
      if (isManualTap && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please enter your 4-digit PIN';
        });
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  void _onDigit(String digit) {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin(_enteredPin);
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClear() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _enteredPin = '';
      });
    }
  }

  void _verifyPin(String pin) {
    final settings = ref.read(settingsProvider);
    final correctPin = settings.appLockPin;

    if (pin == correctPin) {
      HapticFeedback.mediumImpact();
      _unlockApp();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Try again.';
      });
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && _hasError) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  void _unlockApp() {
    ref.read(isUnlockedProvider.notifier).state = true;
    context.go(AppRoutes.dashboard);
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    final defaultBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? defaultBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    const digitStyle = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Lock Icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 38,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(settings.storeName, style: AppTypography.title.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  'Enter 4-digit PIN to continue',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // PIN Dots Indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    Color dotColor;
                    if (_hasError) {
                      dotColor = AppColors.errorRed;
                    } else if (isFilled) {
                      dotColor = theme.colorScheme.primary;
                    } else {
                      dotColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: isFilled ? 18 : 14,
                      height: isFilled ? 18 : 14,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: AppTypography.captionBold.copyWith(color: AppColors.errorRed),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // On-Screen Keypad
                // Row 1: 1, 2, 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildKeypadButton(
                      child: const Text('1', style: digitStyle),
                      onTap: () => _onDigit('1'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('2', style: digitStyle),
                      onTap: () => _onDigit('2'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('3', style: digitStyle),
                      onTap: () => _onDigit('3'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: 4, 5, 6
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildKeypadButton(
                      child: const Text('4', style: digitStyle),
                      onTap: () => _onDigit('4'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('5', style: digitStyle),
                      onTap: () => _onDigit('5'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('6', style: digitStyle),
                      onTap: () => _onDigit('6'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 3: 7, 8, 9
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildKeypadButton(
                      child: const Text('7', style: digitStyle),
                      onTap: () => _onDigit('7'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('8', style: digitStyle),
                      onTap: () => _onDigit('8'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('9', style: digitStyle),
                      onTap: () => _onDigit('9'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 4: Biometrics / Clear, 0, Backspace
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (settings.isBiometricEnabled)
                      _buildKeypadButton(
                        child: Icon(Icons.fingerprint_rounded, size: 30, color: theme.colorScheme.primary),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _checkBiometrics(isManualTap: true);
                        },
                      )
                    else
                      _buildKeypadButton(
                        child: const Text(
                          'C',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.errorRed),
                        ),
                        onTap: _onClear,
                      ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: const Text('0', style: digitStyle),
                      onTap: () => _onDigit('0'),
                    ),
                    const SizedBox(width: 22),
                    _buildKeypadButton(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 24,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onTap: _onBackspace,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LockSettingsScreen extends ConsumerStatefulWidget {
  const LockSettingsScreen({super.key});

  @override
  ConsumerState<LockSettingsScreen> createState() => _LockSettingsScreenState();
}

class _LockSettingsScreenState extends ConsumerState<LockSettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceBiometrics();
  }

  Future<void> _checkDeviceBiometrics() async {
    try {
      final available = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      setState(() => _canCheckBiometrics = available);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _saveNewPin(bool isLockEnabled) async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits')),
      );
      return;
    }

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    await ref.read(settingsProvider.notifier).updateSettings({
      'app_lock_enabled': 'true',
      'app_lock_pin': pin,
    });

    _pinController.clear();
    _confirmPinController.clear();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App Lock PIN updated successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _showSetPinDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set 4-Digit Security PIN', style: AppTypography.title.copyWith(fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New 4-digit PIN'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _saveNewPin(true),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: const Text('Save PIN & Enable Lock'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Security & App Lock'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable App Lock'),
            subtitle: const Text('Require PIN or fingerprint when opening Shopmate'),
            value: settings.isAppLockEnabled,
            onChanged: (val) async {
              if (val) {
                if (settings.appLockPin.isEmpty) {
                  _showSetPinDialog();
                } else {
                  await ref.read(settingsProvider.notifier).updateSetting('app_lock_enabled', 'true');
                }
              } else {
                await ref.read(settingsProvider.notifier).updateSetting('app_lock_enabled', 'false');
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change Security PIN'),
            subtitle: Text(settings.appLockPin.isEmpty ? 'No PIN set' : 'PIN is currently set'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showSetPinDialog,
          ),
          if (_canCheckBiometrics) ...[
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Fingerprint / Biometric Unlock'),
              subtitle: const Text('Use device biometrics for instantaneous unlock'),
              value: settings.isBiometricEnabled,
              onChanged: settings.isAppLockEnabled
                  ? (val) async {
                      await ref.read(settingsProvider.notifier).updateSetting('app_lock_biometric', val.toString());
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
