import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/barcode_utils.dart';

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
          content: Text('Weighing scale label settings saved'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weighing Scale Labels'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Configuration', style: AppTypography.heading3),
          const SizedBox(height: 6),
          const Text(
            'Configure barcode rules used by electronic weighing scales (embedded weight or price).',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Scale Prefix (e.g., 2, 02)',
                      helperText: 'Barcodes starting with this prefix are treated as scale labels',
                    ),
                    onChanged: (_) => _runTestParsing(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _itemCodeLenController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Item Code Length (digits)',
                      helperText: 'Number of digits reserved for product SKU / code (default: 5)',
                    ),
                    onChanged: (_) => _runTestParsing(),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Embedded Value Type', style: AppTypography.captionBold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'weight', label: Text('Weight in grams')),
                      ButtonSegment(value: 'price', label: Text('Price in paise')),
                    ],
                    selected: {_valType},
                    onSelectionChanged: (set) {
                      setState(() => _valType = set.first);
                      _runTestParsing();
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _valLenController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Value Length (digits)'),
                          onChanged: (_) => _runTestParsing(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _decimalPlacesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Decimal Places'),
                          onChanged: (_) => _runTestParsing(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Configuration'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Live Test Parsing', style: AppTypography.heading3),
          const SizedBox(height: 6),
          const Text(
            'Type or scan a sample label (e.g. 200123015004) to test parsing live.',
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
                    controller: _testBarcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Sample Barcode',
                      hintText: 'e.g. 200123015004',
                      prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_testResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testResult!.isScaleBarcode
                            ? AppColors.primaryTeal.withValues(alpha: 0.1)
                            : AppColors.accentAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testResult!.isScaleBarcode ? AppColors.primaryTeal : AppColors.accentAmber,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _testResult!.isScaleBarcode ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: _testResult!.isScaleBarcode ? AppColors.primaryTeal : AppColors.accentAmber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _testResult!.isScaleBarcode ? 'Valid Scale Barcode' : 'Not a scale barcode',
                                style: AppTypography.captionBold.copyWith(
                                  color: _testResult!.isScaleBarcode ? AppColors.primaryTeal : AppColors.accentAmber,
                                ),
                              ),
                            ],
                          ),
                          if (_testResult!.isScaleBarcode) ...[
                            const SizedBox(height: 8),
                            Text('Item Code: ${_testResult!.itemCode}', style: AppTypography.bodyMedium),
                            Text('Embedded ${_testResult!.valueType}: ${_testResult!.formattedValue}', style: AppTypography.bodyMedium),
                            const SizedBox(height: 6),
                            Text(
                              _matchedProduct != null
                                  ? 'Matched Product: ${_matchedProduct!.displayName}'
                                  : 'Catalog Match: No product has item code "${_testResult!.itemCode}"',
                              style: AppTypography.caption.copyWith(
                                color: _matchedProduct != null ? AppColors.successGreen : AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else if (_testResult!.error != null) ...[
                            const SizedBox(height: 6),
                            Text('Error: ${_testResult!.error}', style: AppTypography.caption),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
