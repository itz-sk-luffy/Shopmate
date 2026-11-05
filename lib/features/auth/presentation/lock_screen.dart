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
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  String _enteredPin = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBiometrics();
        _pinFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final settings = ref.read(settingsProvider);
    if (settings.isBiometricEnabled) {
      try {
        final canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (canAuthenticate) {
          final didAuthenticate = await _auth.authenticate(
            localizedReason: 'Please authenticate to unlock Shopmate POS',
            options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
          );
          if (didAuthenticate && mounted) {
            _unlockApp();
          }
        }
      } catch (_) {
        // Biometrics unavailable or cancelled, fallback to PIN
      }
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
        _enteredPin = '';
        _pinController.clear();
      });
      _pinFocus.requestFocus();
    }
  }

  void _unlockApp() {
    ref.read(isUnlockedProvider.notifier).state = true;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pinFocus.requestFocus(),
        child: SafeArea(
          child: Stack(
            children: [
              // Hidden offstage textfield driving native device numpad
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _pinFocus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _enteredPin = val;
                        _hasError = false;
                        _errorMessage = '';
                      });
                      if (val.length == 4) {
                        _verifyPin(val);
                      }
                    },
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Lock Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(settings.storeName, style: AppTypography.title),
                      const SizedBox(height: 6),
                      Text(
                        'Enter 4-digit PIN to continue',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // PIN Dots Indicator (tap to focus device keyboard)
                      InkWell(
                        onTap: () => _pinFocus.requestFocus(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
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
                                dotColor = theme.colorScheme.outline.withValues(alpha: 0.3);
                              }

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: isFilled ? 20 : 16,
                                height: isFilled ? 20 : 16,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: AppTypography.captionBold.copyWith(color: AppColors.errorRed),
                        ),

                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => _pinFocus.requestFocus(),
                        icon: const Icon(Icons.dialpad_rounded, size: 18),
                        label: const Text('Open Device Numpad'),
                      ),

                      // Biometric quick button if enabled
                      if (settings.isBiometricEnabled) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _checkBiometrics,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Unlock with Fingerprint'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(200, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
