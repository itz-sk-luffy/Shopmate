import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../core/services/launcher_icon_service.dart';
import '../../pos/data/billing_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _appNameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _gstinController;
  late final TextEditingController _stateController;
  late final TextEditingController _licenseController;
  late final TextEditingController _footerController;
  late final TextEditingController _billPrefixController;
  late final TextEditingController _billNextNumController;

  late String _currency;
  late String _dateFormat;
  late String _language;
  late bool _gstEnabled;
  late String _taxType;
  late String _defaultTaxRate;
  late String _themeMode;
  late String _accentColorHex;
  late int _launcherIconPreset;
  late bool _reduceAnimations;
  late bool _receiptShowGst;
  late bool _receiptShowCustomer;
  late bool _receiptShowFooter;
  late int _printCutFeed;
  late String _receiptCurrencySymbol;
  late String _searchEngine;
  String? _logoPath;

  late bool _sameBarcodeAddsQuantity;
  late bool _barcodeAutofillOnline;
  late bool _devModeEnabled;
  late bool _showPerformanceOverlay;
  int _versionTapCount = 0;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = ref.read(settingsProvider);
      _appNameController = TextEditingController(text: s.get('app_display_name', 'Shopmate'));
      _storeNameController = TextEditingController(text: s.storeName);
      _addressController = TextEditingController(text: s.storeAddress);
      _phoneController = TextEditingController(text: s.storePhone);
      _emailController = TextEditingController(text: s.storeEmail);
      _gstinController = TextEditingController(text: s.storeGstin);
      _stateController = TextEditingController(text: s.storeState);
      _licenseController = TextEditingController(text: s.storeLicense);
      _footerController = TextEditingController(text: s.storeFooter);
      _billPrefixController = TextEditingController(text: s.billPrefix);
      _billNextNumController = TextEditingController(text: s.billNextNumber.toString());
      final billingRepo = ref.read(billingRepositoryProvider);
      billingRepo.computeNextBillNumericSuffix(s.billPrefix, s.billNextNumber).then((computedNext) {
        if (mounted && _billNextNumController.text == s.billNextNumber.toString()) {
          _billNextNumController.text = computedNext.toString();
        }
      });

      _currency = '₹';
      _dateFormat = s.dateFormat;
      _language = s.language.isEmpty ? 'en' : s.language;
      _gstEnabled = s.gstEnabled;
      _taxType = s.taxType;
      _defaultTaxRate = s.taxRateDefault.toInt().toString();

      _gstinController.addListener(() {
        final derived = deriveStateFromGstin(_gstinController.text);
        if (derived != null && _stateController.text != derived) {
          setState(() {
            _stateController.text = derived;
          });
        }
      });
      _themeMode = s.get('theme_mode', 'system');
      _accentColorHex = s.get('accent_color', '0xFF0F766E');
      _launcherIconPreset = s.launcherIconPreset;
      _reduceAnimations = s.reduceAnimations;
      _receiptShowGst = s.receiptShowGst;
      _receiptShowCustomer = s.receiptShowCustomer;
      _receiptShowFooter = s.receiptShowFooter;
      _printCutFeed = s.printCutFeed;
      _receiptCurrencySymbol = (s.receiptCurrencySymbol == 'Rs.' || s.receiptCurrencySymbol == 'INR' || s.receiptCurrencySymbol.isEmpty)
          ? '₹'
          : s.receiptCurrencySymbol;
      _searchEngine = s.searchEngine;
      _logoPath = s.logoPath.isEmpty ? null : s.logoPath;

      _sameBarcodeAddsQuantity = s.sameBarcodeAddsQuantity;
      _barcodeAutofillOnline = s.barcodeAutofillOnline;
      _devModeEnabled = s.devModeEnabled;
      _showPerformanceOverlay = s.showPerformanceOverlay;

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _stateController.dispose();
    _licenseController.dispose();
    _footerController.dispose();
    _billPrefixController.dispose();
    _billNextNumController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 600, imageQuality: 85);
      if (picked != null) {
        final dir = await getApplicationDocumentsDirectory();
        final ext = p.extension(picked.path);
        final fileName = 'store_logo_${DateTime.now().millisecondsSinceEpoch}$ext';
        final savedFile = await File(picked.path).copy(p.join(dir.path, fileName));
        setState(() {
          _logoPath = savedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick logo: $e')),
        );
      }
    }
  }

  Future<void> _changeLauncherIcon(LauncherIconPreset preset) async {
    if (_launcherIconPreset == preset.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change App Icon?'),
        content: Text(
          'Change application icon to "${preset.title}"? Your home screen icon will update shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _launcherIconPreset = preset.id);
      await LauncherIconService.setLauncherIcon(preset.id);
      await ref.read(settingsProvider.notifier).updateSetting(
            'launcher_icon_preset',
            preset.id.toString(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App icon updated to ${preset.title}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final newSettings = {
      'app_display_name': _appNameController.text.trim(),
      'store_name': _storeNameController.text.trim(),
      'store_address': _addressController.text.trim(),
      'store_phone': _phoneController.text.trim(),
      'store_email': _emailController.text.trim(),
      'store_gstin': _gstinController.text.trim(),
      'store_state': _stateController.text.trim(),
      'store_license': _licenseController.text.trim(),
      'store_footer': _footerController.text.trim(),
      'store_logo_path': _logoPath ?? '',
      'bill_prefix': _billPrefixController.text.trim(),
      'bill_next_number': _billNextNumController.text.trim(),
      'currency_symbol': _currency,
      'date_format': _dateFormat,
      'language': _language,
      'gst_enabled': _gstEnabled.toString(),
      'tax_type': _taxType,
      'tax_rate_default': _defaultTaxRate,
      'theme_mode': _themeMode,
      'accent_color': _accentColorHex,
      'launcher_icon_preset': _launcherIconPreset.toString(),
      'reduce_animations': _reduceAnimations.toString(),
      'receipt_show_gst': _receiptShowGst.toString(),
      'receipt_show_customer': _receiptShowCustomer.toString(),
      'receipt_show_footer': _receiptShowFooter.toString(),
      'print_cut_feed': _printCutFeed.toString(),
      'receipt_currency_symbol': _receiptCurrencySymbol,
      'search_engine': _searchEngine,
      'user_role': 'owner',
      'same_barcode_adds_quantity': _sameBarcodeAddsQuantity.toString(),
      'barcode_autofill_online': _barcodeAutofillOnline.toString(),
      'print_bill_barcode': 'false',
      'dev_mode_enabled': _devModeEnabled.toString(),
      'show_performance_overlay': _showPerformanceOverlay.toString(),
    };

    await ref.read(settingsProvider.notifier).updateSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Settings & Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Settings',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Store Branding & Logo Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branding & Display', style: AppTypography.section),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          backgroundImage: _logoPath != null && File(_logoPath!).existsSync()
                              ? FileImage(File(_logoPath!))
                              : null,
                          child: _logoPath == null || !File(_logoPath!).existsSync()
                              ? Icon(Icons.storefront_rounded, size: 36, color: theme.colorScheme.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              _showImageSourceDialog();
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _appNameController,
                            decoration: const InputDecoration(
                              labelText: 'App Display Name',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Shown in app bar, splash, and reports',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),



          // Store Profile Details
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store Profile & Invoicing', style: AppTypography.section),
                const SizedBox(height: 14),
                TextField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(labelText: 'Store Name *', prefixIcon: Icon(Icons.store)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address / Location *', prefixIcon: Icon(Icons.place_outlined)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gstinController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'GSTIN (Optional)', prefixIcon: Icon(Icons.badge_outlined)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseController,
                  decoration: const InputDecoration(labelText: 'Trade / Food License No.', prefixIcon: Icon(Icons.verified_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _footerController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Receipt Footer Message', prefixIcon: Icon(Icons.notes_outlined)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories Management Section
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Product Categories', style: AppTypography.section),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      tooltip: 'Manage Categories',
                      onPressed: () => context.push(AppRoutes.categories),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Add or remove categories, rename them, and assign multiple products in bulk.',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.categories),
                  icon: const Icon(Icons.category_rounded, size: 18),
                  label: const Text('Manage Categories & Assign Products'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Invoice Numbering & Tax Settings
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bill Prefix & Tax', style: AppTypography.section),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _billPrefixController,
                        decoration: const InputDecoration(labelText: 'Bill Prefix'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _billNextNumController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Next Bill Number'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable GST Calculation', style: AppTypography.bodyMedium),
                  subtitle: const Text('Calculate CGST, SGST & IGST on bills', style: AppTypography.caption),
                  value: _gstEnabled,
                  onChanged: (val) => setState(() => _gstEnabled = val),
                ),
                if (_gstEnabled) ...[
                  const SizedBox(height: 12),
                  const Text('Price Mode', style: AppTypography.bodyMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'exclusive', label: Text('Prices Exclude GST')),
                      ButtonSegment(value: 'inclusive', label: Text('Prices Include GST')),
                    ],
                    selected: {_taxType},
                    onSelectionChanged: (set) => setState(() => _taxType = set.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('Default GST Rate (%)', style: AppTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    "A product's own GST % overrides this default rate.",
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['0', '5', '12', '18', '28'].map((r) {
                      final isSel = _defaultTaxRate == r;
                      return ChoiceChip(
                        label: Text('$r%'),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => _defaultTaxRate = r);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Regional & Formatting
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Format & Regional', style: AppTypography.section),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Currency Symbol', style: AppTypography.bodyMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.currency_rupee_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '₹ (Rupees)',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Date Format', style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'].map((df) {
                    final isSel = _dateFormat == df;
                    return ChoiceChip(
                      label: Text(df),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _dateFormat = df);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appearance & Theme Mode
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme & Accent Color', style: AppTypography.section),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto), label: Text('Auto')),
                    ButtonSegment(value: 'light', icon: Icon(Icons.light_mode), label: Text('Light')),
                    ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode), label: Text('Dark')),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (set) {
                    final newMode = set.first;
                    setState(() => _themeMode = newMode);
                    ref.read(settingsProvider.notifier).updateSetting('theme_mode', newMode);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Accent Seed Color', style: AppTypography.bodyMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: AppColors.presetColors.map((col) {
                    final hex = '0x${col.toARGB32().toRadixString(16).toUpperCase()}';
                    final isSel = _accentColorHex == hex;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _accentColorHex = hex);
                        ref.read(settingsProvider.notifier).updateSetting('accent_color', hex);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: [
                            if (isSel)
                              BoxShadow(
                                color: col.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: isSel ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce Animations'),
                  subtitle: const Text('Optimizes frame rates on Poco C51 / low-end Android Go devices'),
                  value: _reduceAnimations,
                  onChanged: (val) {
                    setState(() => _reduceAnimations = val);
                    ref.read(settingsProvider.notifier).updateSetting('reduce_animations', val.toString());
                  },
                ),
                const SizedBox(height: 16),
                const Text('App Launcher Icon', style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                const Text(
                  'Select the icon displayed on your phone home screen',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: LauncherIconService.presets.length,
                  itemBuilder: (context, index) {
                    final preset = LauncherIconService.presets[index];
                    final isSelected = _launcherIconPreset == preset.id;
                    return InkWell(
                      onTap: () => _changeLauncherIcon(preset),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF0F3D39) : const Color(0xFFD8EEEA))
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    preset.assetPath,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              preset.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                                color: isSelected
                                    ? (isDark ? Colors.tealAccent : const Color(0xFF0F766E))
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preset.description,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Receipt Layout Toggles
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('58 mm Thermal Receipt Layout', style: AppTypography.section),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show GST Breakup'),
                  subtitle: const Text('Prints CGST and SGST summary table'),
                  value: _receiptShowGst,
                  onChanged: (val) => setState(() => _receiptShowGst = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Customer Details'),
                  subtitle: const Text('Prints customer name and phone on receipt'),
                  value: _receiptShowCustomer,
                  onChanged: (val) => setState(() => _receiptShowCustomer = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Store Footer Text'),
                  subtitle: const Text('Prints custom thank you message'),
                  value: _receiptShowFooter,
                  onChanged: (val) => setState(() => _receiptShowFooter = val),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Receipt currency symbol'),
                    DropdownButton<String>(
                      value: ['₹', 'Rs.'].contains(_receiptCurrencySymbol) ? _receiptCurrencySymbol : '₹',
                      items: const [
                        DropdownMenuItem(value: '₹', child: Text('₹ (Rupee)')),
                        DropdownMenuItem(value: 'Rs.', child: Text('Rs. (Standard)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _receiptCurrencySymbol = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paper Feed After Print'),
                    DropdownButton<int>(
                      value: _printCutFeed,
                      items: [1, 2, 3, 4, 5].map((lines) {
                        return DropdownMenuItem(value: lines, child: Text('$lines lines'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _printCutFeed = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Engine Setting for Product Images
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image Search Engine', style: AppTypography.section),
                const SizedBox(height: 6),
                Text(
                  'Default engine used for in-app web image search',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'google', label: Text('Google')),
                    ButtonSegment(value: 'bing', label: Text('Bing')),
                    ButtonSegment(value: 'duckduckgo', label: Text('DuckDuckGo')),
                  ],
                  selected: {_searchEngine},
                  onSelectionChanged: (set) => setState(() => _searchEngine = set.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),



          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Barcodes & Hardware', style: AppTypography.section),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Same barcode again adds quantity', style: AppTypography.bodyMedium),
                  subtitle: const Text('Scanning the same item again increments quantity by 1 after debounce', style: AppTypography.caption),
                  value: _sameBarcodeAddsQuantity,
                  onChanged: (val) => setState(() => _sameBarcodeAddsQuantity = val),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-fill from barcode when online', style: AppTypography.bodyMedium),
                  subtitle: const Text('Look up name, brand & image from Open Food Facts on new barcodes', style: AppTypography.caption),
                  value: _barcodeAutofillOnline,
                  onChanged: (val) => setState(() => _barcodeAutofillOnline = val),
                ),

              ],
            ),
          ),
          const SizedBox(height: 16),

          // Developer Options Card (visible when enabled via 7-tap)
          if (_devModeEnabled) ...[
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.developer_mode_rounded, color: AppColors.primaryTeal),
                      SizedBox(width: 8),
                      Text('Developer & Performance Options', style: AppTypography.section),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Performance Overlay', style: AppTypography.bodyMedium),
                    subtitle: const Text('Display real-time GPU raster & UI thread rendering FPS charts', style: AppTypography.caption),
                    value: _showPerformanceOverlay,
                    onChanged: (val) {
                      setState(() => _showPerformanceOverlay = val);
                      ref.read(settingsProvider.notifier).updateSetting('show_performance_overlay', val.toString());
                    },
                  ),
                  const Divider(),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Scan-to-Cart Timing Log', style: AppTypography.bodyMedium),
                    subtitle: Text('Target: < 100 ms after decode. Timing is logged to console and on-screen chip during scanning.', style: AppTypography.caption),
                    trailing: Icon(Icons.speed_rounded, color: AppColors.primaryTeal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Save Button
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save All Settings'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 24),

          // About & Version Card with 7-tap Developer Easter Egg & Open Food Facts Attribution
          Center(
            child: GestureDetector(
              onTap: () {
                _versionTapCount++;
                if (_versionTapCount >= 7) {
                  _versionTapCount = 0;
                  setState(() => _devModeEnabled = !_devModeEnabled);
                  ref.read(settingsProvider.notifier).updateSetting('dev_mode_enabled', _devModeEnabled.toString());
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_devModeEnabled ? 'Developer Mode is now ENABLED!' : 'Developer Mode is now DISABLED'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
                  );
                } else if (_versionTapCount >= 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You are ${7 - _versionTapCount} steps away from Developer Mode'),
                      duration: const Duration(milliseconds: 600),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text('Shopmate v1.0.0 (Build 1)', style: AppTypography.captionBold.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      'Developed by Srikanth',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Data: Open Food Facts (Open Database License)', style: AppTypography.caption.copyWith(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickLogo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickLogo(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
