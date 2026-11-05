import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/barcode_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/barcode_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import 'weight_input_sheet.dart';

class FastScanSheet extends ConsumerStatefulWidget {
  const FastScanSheet({super.key});

  @override
  ConsumerState<FastScanSheet> createState() => _FastScanSheetState();
}

class _FastScanSheetState extends ConsumerState<FastScanSheet> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _isPriceCheckMode = false;
  bool _isTorchOn = false;
  bool _showTorchHint = false;
  Timer? _torchHintTimer;
  Timer? _undoDismissTimer;

  // Debounce tracking
  String? _lastScannedCode;
  int _lastScannedTimeMs = 0;

  // Last added item chip state
  ({String title, double quantity, String unit, int itemIndex, double previousQty})? _lastAdded;

  // Price check result state
  BarcodeProductMatch? _priceCheckMatch;
  String? _priceCheckUnmatchedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
      ],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 300,
      cameraResolution: const Size(640, 480),
      returnImage: false,
    );

    _startTorchHintTimer();
  }

  void _startTorchHintTimer() {
    _torchHintTimer?.cancel();
    _torchHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isTorchOn) {
        setState(() {
          _showTorchHint = true;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _torchHintTimer?.cancel();
    _undoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final rawCode = BarcodeUtils.sanitize(barcodes.first.rawValue!);
    if (rawCode.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final settings = ref.read(settingsProvider);

    // Debounce: ignore same code within 800 ms
    if (_lastScannedCode == rawCode) {
      final diff = nowMs - _lastScannedTimeMs;
      if (diff < 800) return;
      if (!settings.sameBarcodeAddsQuantity) return;
    }

    _lastScannedCode = rawCode;
    _lastScannedTimeMs = nowMs;

    // Reset low-light torch hint
    _torchHintTimer?.cancel();
    if (_showTorchHint) {
      setState(() => _showTorchHint = false);
    }

    // Preloaded sound & light haptic with no delay
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.lightImpact();

    final cacheService = ref.read(barcodeCacheServiceProvider);

    // Check weighing scale barcode prefix
    if (rawCode.startsWith(settings.scalePrefix) &&
        rawCode.length >= (settings.scalePrefix.length + settings.scaleItemCodeLength + settings.scaleValueLength)) {
      final scaleResult = BarcodeUtils.parseScaleBarcode(
        rawBarcode: rawCode,
        prefix: settings.scalePrefix,
        itemCodeLength: settings.scaleItemCodeLength,
        valueType: settings.scaleValueType,
        valueLength: settings.scaleValueLength,
        decimalPlaces: settings.scaleDecimalPlaces,
      );

      if (scaleResult.isScaleBarcode && scaleResult.itemCode != null) {
        final match = await cacheService.findByBarcode(scaleResult.itemCode!) ??
            await cacheService.findByBarcode(rawCode);

        if (!mounted) return;

        if (match != null) {
          if (_isPriceCheckMode) {
            setState(() {
              _priceCheckMatch = match;
              _priceCheckUnmatchedCode = null;
            });
            return;
          }

          final cartNotifier = ref.read(cartProvider.notifier);
          final cartState = ref.read(cartProvider);
          final existingIdx = cartState.items.indexWhere((it) => it.productId == match.product.id);
          final prevQty = existingIdx >= 0 ? cartState.items[existingIdx].quantity : 0.0;

          final qty = scaleResult.valueType == 'weight' ? (scaleResult.value ?? 1.0) : 1.0;
          cartNotifier.addItem(match.product, quantity: qty);

          _showAddedChip(
            title: match.displayName,
            quantity: prevQty + qty,
            unit: match.product.unit,
            itemIndex: existingIdx >= 0 ? existingIdx : cartState.items.length,
            previousQty: prevQty,
            product: match.product,
          );
          return;
        }
      }
    }

    // Standard barcode lookup
    final match = await cacheService.findByBarcode(rawCode);

    if (!mounted) return;

    if (match != null) {
      if (_isPriceCheckMode) {
        setState(() {
          _priceCheckMatch = match;
          _priceCheckUnmatchedCode = null;
        });
        return;
      }

      final isWeightItem = match.product.unit == 'kg' ||
          match.product.unit == 'ltr' ||
          match.product.unit == 'gm' ||
          match.product.unit == 'ml';

      final cartNotifier = ref.read(cartProvider.notifier);
      final cartState = ref.read(cartProvider);
      final existingIdx = cartState.items.indexWhere((it) => it.productId == match.product.id);
      final prevQty = existingIdx >= 0 ? cartState.items[existingIdx].quantity : 0.0;

      if (isWeightItem && existingIdx < 0) {
        _controller.stop();
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => WeightInputSheet(
            product: match.product,
            currencySymbol: settings.currencySymbol,
            onAdd: (qty) {
              cartNotifier.addItem(match.product, quantity: qty);
              _showAddedChip(
                title: match.displayName,
                quantity: prevQty + qty,
                unit: match.product.unit,
                itemIndex: existingIdx >= 0 ? existingIdx : cartState.items.length,
                previousQty: prevQty,
                product: match.product,
              );
            },
          ),
        );
        if (mounted) _controller.start();
      } else {
        cartNotifier.addItem(match.product, quantity: 1.0);
        _showAddedChip(
          title: match.displayName,
          quantity: prevQty + 1.0,
          unit: match.product.unit,
          itemIndex: existingIdx >= 0 ? existingIdx : cartState.items.length,
          previousQty: prevQty,
          product: match.product,
        );
      }
    } else {
      // Unmatched barcode
      HapticFeedback.vibrate();
      await cacheService.logUnmatchedScan(rawCode);

      if (!mounted) return;

      if (_isPriceCheckMode) {
        setState(() {
          _priceCheckMatch = null;
          _priceCheckUnmatchedCode = rawCode;
        });
      } else {
        _showUnmatchedChip(rawCode);
      }
    }
  }

  void _showAddedChip({
    required String title,
    required double quantity,
    required String unit,
    required int itemIndex,
    required double previousQty,
    required dynamic product,
  }) {
    _undoDismissTimer?.cancel();
    setState(() {
      _lastAdded = (
        title: title,
        quantity: quantity,
        unit: unit,
        itemIndex: itemIndex,
        previousQty: previousQty,
      );
    });

    _undoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _lastAdded = null);
      }
    });
  }

  void _showUnmatchedChip(String code) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unmatched barcode: $code (logged)'),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _undoLastAdd() {
    _undoDismissTimer?.cancel();
    if (_lastAdded == null) return;

    final cartNotifier = ref.read(cartProvider.notifier);
    final prev = _lastAdded!.previousQty;
    final idx = _lastAdded!.itemIndex;

    if (prev <= 0.0001) {
      cartNotifier.removeItem(idx);
    } else {
      cartNotifier.updateQuantity(idx, prev);
    }

    HapticFeedback.mediumImpact();
    setState(() => _lastAdded = null);
  }

  void _openQuantityKeypad() async {
    if (_lastAdded == null) return;
    final currentLast = _lastAdded!;
    final cartState = ref.read(cartProvider);
    if (currentLast.itemIndex >= cartState.items.length) return;

    final item = cartState.items[currentLast.itemIndex];
    final qtyController = TextEditingController(text: item.quantity.toString());

    _controller.stop();
    final newQtyStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Quantity: ${item.productName}', style: AppTypography.heading3),
        content: TextField(
          controller: qtyController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quantity (${item.unit})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, qtyController.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (mounted) _controller.start();

    if (newQtyStr != null) {
      final parsed = double.tryParse(newQtyStr);
      if (parsed != null && parsed > 0) {
        ref.read(cartProvider.notifier).updateQuantity(currentLast.itemIndex, parsed);
        setState(() {
          _lastAdded = (
            title: currentLast.title,
            quantity: parsed,
            unit: currentLast.unit,
            itemIndex: currentLast.itemIndex,
            previousQty: currentLast.previousQty,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(settingsProvider.select((s) => s.currencySymbol));

    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.darkTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    _isPriceCheckMode ? 'Price Check Scanner' : 'Continuous Barcode Scanner',
                    style: AppTypography.heading3.copyWith(color: AppColors.darkTextPrimary),
                  ),
                ),
                // Torch Button
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isTorchOn ? AppColors.warningAmber : AppColors.darkTextPrimary,
                  ),
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                      _showTorchHint = false;
                    });
                  },
                ),
                // Price-check mode toggle
                FilterChip(
                  label: const Text('Price Check', style: AppTypography.caption),
                  selected: _isPriceCheckMode,
                  onSelected: (val) {
                    setState(() {
                      _isPriceCheckMode = val;
                      _priceCheckMatch = null;
                      _priceCheckUnmatchedCode = null;
                    });
                  },
                  selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryTeal,
                ),
              ],
            ),
          ),

          // Low-light torch hint banner
          if (_showTorchHint && !_isTorchOn)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warningAmber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Low light? Turn on torch for faster decode',
                      style: AppTypography.caption.copyWith(color: AppColors.warningAmber),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _controller.toggleTorch();
                      setState(() {
                        _isTorchOn = true;
                        _showTorchHint = false;
                      });
                    },
                    child: const Text('Turn On'),
                  ),
                ],
              ),
            ),

          // Camera View with Scan Window Cutout
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),

                // Cropped scan target viewfinder
                Container(
                  width: 260,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryTeal,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Price Check Result Overlay Card
                if (_isPriceCheckMode && (_priceCheckMatch != null || _priceCheckUnmatchedCode != null))
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Card(
                      color: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.primaryTeal),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _priceCheckMatch != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _priceCheckMatch!.displayName,
                                          style: AppTypography.heading3.copyWith(color: AppColors.darkTextPrimary),
                                        ),
                                      ),
                                      Text(
                                        Formatters.currency(_priceCheckMatch!.price, symbol: currencySymbol),
                                        style: AppTypography.heading3.copyWith(
                                          color: AppColors.primaryTeal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Unit: ${_priceCheckMatch!.unit} • Barcode: ${_priceCheckMatch!.barcode}',
                                    style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                                      label: const Text('Add to Bill'),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).addItem(_priceCheckMatch!.product);
                                        setState(() => _priceCheckMatch = null);
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No product for barcode: $_priceCheckUnmatchedCode',
                                      style: AppTypography.caption.copyWith(color: AppColors.darkTextPrimary),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                // "Added: ... x2" Chip with Undo (shown for 3 seconds)
                if (!_isPriceCheckMode && _lastAdded != null)
                  Positioned(
                    bottom: 24,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(24),
                      color: AppColors.darkSurface,
                      child: InkWell(
                        onTap: _openQuantityKeypad,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primaryTeal, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Added: ${_lastAdded!.title}  x${_lastAdded!.quantity % 1 == 0 ? _lastAdded!.quantity.toInt() : _lastAdded!.quantity}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.darkTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(tap to edit)',
                                style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary, fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: _undoLastAdd,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Undo',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.errorRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
