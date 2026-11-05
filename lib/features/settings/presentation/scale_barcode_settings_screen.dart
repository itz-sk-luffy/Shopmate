import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/barcode_utils.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';

class ScaleBarcodeSettingsScreen extends ConsumerStatefulWidget {
  const ScaleBarcodeSettingsScreen({super.key});

  @override
  ConsumerState<ScaleBarcodeSettingsScreen> createState() => _ScaleBarcodeSettingsScreenState();
}

class _ScaleBarcodeSettingsScreenState extends ConsumerState<ScaleBarcodeSettingsScreen> {
  late TextEditingController _prefixController;
  late TextEditingController _itemCodeLenController;
  late TextEditingController _valLenController;
  late TextEditingController _decimalPlacesController;
  late String _valType;

  final TextEditingController _testBarcodeController = TextEditingController();
  ScaleBarcodeResult? _testResult;
  BarcodeProductMatch? _matchedProduct;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _prefixController = TextEditingController(text: s.scalePrefix);
    _itemCodeLenController = TextEditingController(text: s.scaleItemCodeLength.toString());
    _valLenController = TextEditingController(text: s.scaleValueLength.toString());
    _decimalPlacesController = TextEditingController(text: s.scaleDecimalPlaces.toString());
    _valType = s.scaleValueType;

    _testBarcodeController.addListener(_runTestParsing);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _itemCodeLenController.dispose();
    _valLenController.dispose();
    _decimalPlacesController.dispose();
    _testBarcodeController.dispose();
    super.dispose();
  }

  void _runTestParsing() async {
    final raw = _testBarcodeController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _testResult = null;
        _matchedProduct = null;
      });
      return;
    }

    final prefix = _prefixController.text.trim();
    final itemCodeLen = int.tryParse(_itemCodeLenController.text.trim()) ?? 5;
    final valLen = int.tryParse(_valLenController.text.trim()) ?? 5;
    final dec = int.tryParse(_decimalPlacesController.text.trim()) ?? 3;

    final parsed = BarcodeUtils.parseScaleBarcode(
      rawBarcode: raw,
      prefix: prefix,
      itemCodeLength: itemCodeLen,
      valueType: _valType,
      valueLength: valLen,
      decimalPlaces: dec,
    );

    BarcodeProductMatch? match;
    if (parsed.isScaleBarcode && parsed.itemCode != null) {
      final cacheService = ref.read(barcodeCacheServiceProvider);
      match = await cacheService.findByBarcode(parsed.itemCode!) ??
          await cacheService.findByBarcode(raw);
    }

    if (mounted) {
      setState(() {
        _testResult = parsed;
        _matchedProduct = match;
      });
    }
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateSetting('scale_prefix', _prefixController.text.trim());
    await notifier.updateSetting('scale_item_code_length', _itemCodeLenController.text.trim());
    await notifier.updateSetting('scale_value_type', _valType);
    await notifier.updateSetting('scale_value_length', _valLenController.text.trim());
    await notifier.updateSetting('scale_decimal_places', _decimalPlacesController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weighing scale sticker settings saved successfully'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.settings),
        title: const Text('Weighing Scale Stickers'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Visual Explanation Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text('How Scale Barcode Stickers Work', style: AppTypography.heading3),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'When an electronic weighing scale prints a barcode sticker for weighed products (fruits, vegetables, sweets, loose grains), the barcode encodes the product code and the measured weight together.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 12),

                // Interactive Visual Breakdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Example Sticker Barcode: 2000123015004', style: AppTypography.captionBold),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildVisualBadge('20', 'Prefix', Colors.blue, isDark),
                          _buildVisualBadge('00123', 'Product SKU', AppColors.primaryTeal, isDark),
                          _buildVisualBadge('01500', '1.500 kg', AppColors.accentAmber, isDark),
                          _buildVisualBadge('4', 'Check', Colors.grey, isDark),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shopmate instantly identifies the product "00123", applies 1.5 kg, and calculates the price automatically.',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings Card
          const Text('Sticker Rules & Format', style: AppTypography.heading3),
          const SizedBox(height: 6),
          const Text(
            'Adjust these settings to match your electronic weighing scale machine model (Essae, Phoenix, Citizen, etc.).',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: '1. Scale Prefix (Start Digits)',
                      hintText: 'e.g. 2 or 20 or 02',
                      helperText: 'Tells Shopmate this barcode comes from a weighing scale',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                    onChanged: (_) => _runTestParsing(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _itemCodeLenController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '2. Product Code Length (Digits)',
                      hintText: 'Usually 5',
                      helperText: 'Number of digits that identify the item in your catalog',
                      prefixIcon: Icon(Icons.qr_code_2_rounded),
                    ),
                    onChanged: (_) => _runTestParsing(),
                  ),
                  const SizedBox(height: 16),
                  const Text('3. What does the scale print inside the barcode?', style: AppTypography.captionBold),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'weight',
                        icon: Icon(Icons.scale_rounded, size: 18),
                        label: Text('Weight (Grams)'),
                      ),
                      ButtonSegment(
                        value: 'price',
                        icon: Icon(Icons.payments_rounded, size: 18),
                        label: Text('Total Price'),
                      ),
                    ],
                    selected: {_valType},
                    onSelectionChanged: (set) {
                      setState(() => _valType = set.first);
                      _runTestParsing();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _valLenController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '4. Value Length',
                            hintText: 'Usually 5',
                            helperText: 'Digits for weight/price',
                          ),
                          onChanged: (_) => _runTestParsing(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _decimalPlacesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '5. Decimal Places',
                            hintText: 'Usually 3',
                            helperText: '3 for kg (1500 -> 1.500)',
                          ),
                          onChanged: (_) => _runTestParsing(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Scale Rules'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Live Test Parsing Card
          const Text('Test With A Barcode', style: AppTypography.heading3),
          const SizedBox(height: 6),
          const Text(
            'Type or scan a barcode from your scale sticker to verify it works instantly.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 10),

          // Quick Preset Test Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Sample: 1.500 kg (2000123015004)'),
                  onPressed: () {
                    _testBarcodeController.text = '2000123015004';
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Sample: 0.250 kg (2000123002506)'),
                  onPressed: () {
                    _testBarcodeController.text = '2000123002506';
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _testBarcodeController,
                    decoration: InputDecoration(
                      labelText: 'Barcode Number',
                      hintText: 'Type or scan sample sticker barcode',
                      prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                      suffixIcon: _testBarcodeController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _testBarcodeController.clear(),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_testResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _testResult!.isScaleBarcode
                            ? AppColors.primaryTeal.withValues(alpha: 0.1)
                            : AppColors.accentAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _testResult!.isScaleBarcode ? AppColors.primaryTeal : AppColors.accentAmber,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _testResult!.isScaleBarcode ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                color: _testResult!.isScaleBarcode ? AppColors.primaryTeal : AppColors.accentAmber,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _testResult!.isScaleBarcode ? 'Valid Weighing Scale Sticker' : 'Standard Barcode (Not from Scale)',
                                style: AppTypography.heading3.copyWith(
                                  color: _testResult!.isScaleBarcode ? AppColors.primaryTeal : AppColors.accentAmber,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          if (_testResult!.isScaleBarcode) ...[
                            const SizedBox(height: 10),
                            Text('• Detected Product SKU: ${_testResult!.itemCode}', style: AppTypography.bodyMedium),
                            Text(
                              '• Embedded ${_testResult!.valueType == 'weight' ? 'Weight' : 'Price'}: ${_testResult!.formattedValue}',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _matchedProduct != null ? Icons.inventory_2_rounded : Icons.search_off_rounded,
                                    size: 18,
                                    color: _matchedProduct != null ? AppColors.successGreen : AppColors.accentAmber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _matchedProduct != null
                                          ? 'Catalog Match: ${_matchedProduct!.displayName}'
                                          : 'Catalog: No item with barcode/SKU "${_testResult!.itemCode}" yet',
                                      style: AppTypography.captionBold.copyWith(
                                        color: _matchedProduct != null ? AppColors.successGreen : AppColors.accentAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_testResult!.error != null) ...[
                            const SizedBox(height: 6),
                            Text('Notice: ${_testResult!.error}', style: AppTypography.caption),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildVisualBadge(String code, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(code, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
