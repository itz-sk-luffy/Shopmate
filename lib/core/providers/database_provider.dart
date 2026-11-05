import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../theme/app_colors.dart';
import '../utils/device_utils.dart';

// Database instance provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// App Settings state model
class AppSettingsState {
  final Map<String, String> settings;
  final bool isLoading;

  const AppSettingsState({
    this.settings = const {},
    this.isLoading = true,
  });

  String get(String key, [String defaultValue = '']) => settings[key] ?? defaultValue;

  // Store Profile
  String get storeName => get('store_name', 'Shopmate Store');
  String get storeAddress => get('store_address', 'Main Market');
  String get storePhone => get('store_phone', '');
  String get storeEmail => get('store_email', '');
  String get storeGstin => get('store_gstin', '');
  String get storeState => get('store_state', 'Maharashtra');
  String get storeLicense => get('store_license', '');
  String get storeFooter => get('store_footer', 'Thank you for shopping with us! Visit again.');
  String get logoPath => get('store_logo_path', '');
  String get storeLogoPath => logoPath;

  // Bill numbering & Tax
  String get billPrefix => get('bill_prefix', 'INV-');
  int get billNextNumber => int.tryParse(get('bill_next_number', '1001')) ?? 1001;
  String get currencySymbol => get('currency_symbol', '₹');
  String get dateFormat => get('date_format', 'dd/MM/yyyy');
  String get language => get('language', 'en'); // en, hi, mr
  String get taxType => get('tax_type', 'exclusive'); // exclusive or inclusive
  double get taxRateDefault => double.tryParse(get('tax_rate_default', '0')) ?? 0.0;
  bool get gstEnabled => get('gst_enabled', 'true') == 'true';
  bool get pricesIncludeGst => taxType == 'inclusive';

  // Theme & UI
  int get launcherIconPreset => int.tryParse(get('launcher_icon_preset', '1')) ?? 1;
  ThemeMode get themeMode {
    final mode = get('theme_mode', 'system');
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Color get accentColor {
    final hexStr = get('accent_color', '0xFF0F766E');
    try {
      return Color(int.parse(hexStr));
    } catch (_) {
      return AppColors.primaryTeal;
    }
  }

  bool get reduceAnimations => get('reduce_animations', 'false') == 'true';

  // Receipt Layout
  bool get receiptShowGst => get('receipt_show_gst', 'true') == 'true';
  bool get receiptShowCustomer => get('receipt_show_customer', 'true') == 'true';
  bool get receiptShowFooter => get('receipt_show_footer', 'true') == 'true';
  String get receiptCurrencySymbol => get('receipt_currency_symbol', 'Rs.');
  int get printCutFeed => int.tryParse(get('print_cut_feed', '3')) ?? 3;
  String get printFontSize => get('print_font_size', 'normal');

  // Backup & Lifecycle
  bool get autoBackupEnabled => get('auto_backup_enabled', 'true') == 'true';
  bool get isAutoBackupEnabled => autoBackupEnabled;
  String get autoBackupInterval => get('auto_backup_interval', 'daily');
  bool get hasCompletedOnboarding => get('has_completed_onboarding', 'false') == 'true';

  // Security & Permissions
  bool get isAppLockEnabled => get('app_lock_enabled', 'false') == 'true';
  String get appLockPin => get('app_lock_pin', '');
  bool get isBiometricEnabled => get('app_lock_biometric', 'false') == 'true';
  String get userRole => get('user_role', 'owner'); // owner or cashier
  bool get isOwner => userRole == 'owner';

  // Search Engine
  String get searchEngine => get('search_engine', 'google'); // google, bing, duckduckgo

  // Barcode & Scale Settings
  bool get sameBarcodeAddsQuantity => get('same_barcode_adds_quantity', 'true') == 'true';
  String get scalePrefix => get('scale_prefix', '2');
  int get scaleItemCodeLength => int.tryParse(get('scale_item_code_length', '5')) ?? 5;
  String get scaleValueType => get('scale_value_type', 'weight'); // 'weight' or 'price'
  int get scaleValueLength => int.tryParse(get('scale_value_length', '5')) ?? 5;
  int get scaleDecimalPlaces => int.tryParse(get('scale_decimal_places', '3')) ?? 3;
  String get internalBarcodePrefix => get('internal_barcode_prefix', '29');
  bool get barcodeAutofillOnline => get('barcode_autofill_online', 'false') == 'true';
  bool get printBillBarcode => get('print_bill_barcode', 'false') == 'true';

  // Developer & Performance Mode
  bool get devModeEnabled => get('dev_mode_enabled', 'false') == 'true';
  bool get showPerformanceOverlay => get('show_performance_overlay', 'false') == 'true';

  AppSettingsState copyWith({
    Map<String, String>? settings,
    bool? isLoading,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final AppDatabase _db;

  AppSettingsNotifier(this._db) : super(const AppSettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final map = await _db.getAllSettings();
    state = state.copyWith(settings: map, isLoading: false);

    // Auto-detect low-RAM device (Poco C51 2GB Android Go) and default reduce_animations to true
    if (!map.containsKey('reduce_animations_configured')) {
      final isLow = await DeviceUtils.isLowRamDevice();
      if (isLow) {
        await updateSetting('reduce_animations', 'true');
        await _db.setSetting('reduce_animations_configured', 'true');
      }
    }
  }

  Future<void> updateSetting(String key, String value) async {
    await _db.setSetting(key, value);
    final updated = Map<String, String>.from(state.settings);
    updated[key] = value;
    state = state.copyWith(settings: updated);
  }

  Future<void> updateSettings(Map<String, String> newSettings) async {
    for (final entry in newSettings.entries) {
      await _db.setSetting(entry.key, entry.value);
    }
    final updated = Map<String, String>.from(state.settings);
    updated.addAll(newSettings);
    state = state.copyWith(settings: updated);
  }

  Future<String> getNextBillNumberAndIncrement() async {
    final prefix = state.billPrefix;
    final startNum = state.billNextNumber;
    final rows = await _db.customSelect(
      'SELECT bill_number FROM bills WHERE bill_number LIKE ?',
      variables: [Variable.withString('$prefix%')],
      readsFrom: {_db.bills},
    ).get();

    int maxSuffix = startNum - 1;
    for (final row in rows) {
      final bn = row.read<String>('bill_number');
      if (bn.startsWith(prefix)) {
        final suffixStr = bn.substring(prefix.length);
        final suffixVal = int.tryParse(suffixStr);
        if (suffixVal != null && suffixVal > maxSuffix) {
          maxSuffix = suffixVal;
        }
      }
    }
    final next = maxSuffix + 1;
    final formattedNumber = '$prefix$next';
    await updateSetting('bill_next_number', (next + 1).toString());
    return formattedNumber;
  }
}

final settingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final db = ref.watch(databaseProvider);
  return AppSettingsNotifier(db);
});

// App Lock authenticated state for current app session
final isUnlockedProvider = StateProvider<bool>((ref) => false);
