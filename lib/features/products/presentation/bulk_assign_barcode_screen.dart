import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/barcode_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../data/products_repository.dart';

class BulkAssignBarcodeScreen extends ConsumerStatefulWidget {
  const BulkAssignBarcodeScreen({super.key});

  @override
  ConsumerState<BulkAssignBarcodeScreen> createState() => _BulkAssignBarcodeScreenState();
}

class _BulkAssignBarcodeScreenState extends ConsumerState<BulkAssignBarcodeScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  final TextEditingController _searchController = TextEditingController();

  int _selectedSegment = 0; // 0 = Without barcode, 1 = All products
  int _selectedIndex = 0;
  bool _isTorchOn = false;
  double _zoomScale = 0.0;
  bool _isAttaching = false;
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 300,
      cameraResolution: const Size(640, 480),
      returnImage: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
      ],
    );
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String _keyBuffer = '';
  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_keyBuffer.isNotEmpty) {
          final code = _keyBuffer.trim();
          _keyBuffer = '';
          dev.log('[BulkAssign] External scanner input received: $code', name: 'BulkAssign');
          _processAssignBarcode(code);
          return true;
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        _keyBuffer += event.character!;
      }
    }
    return false;
  }

  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    if (now.difference(_lastScanTime).inMilliseconds < 1000) return; // Debounce scans

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      _lastScanTime = now;
      dev.log('[BulkAssign] Camera barcode detected: $code', name: 'BulkAssign');
      _processAssignBarcode(code);
    }
  }

  List<BarcodeQueueItem> _filterItems(List<BarcodeQueueItem> allItems) {
    final query = _searchController.text.trim().toLowerCase();

    return allItems.where((item) {
      // Segment filter
      if (_selectedSegment == 0 && item.hasBarcode) {
        return false;
      }

      // Search filter
      if (query.isNotEmpty) {
        final matchesName = item.displayName.toLowerCase().contains(query);
        final matchesBarcode = item.barcodes.any((b) => b.toLowerCase().contains(query));
        if (!matchesName && !matchesBarcode) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _processAssignBarcode(String rawBarcode) async {
    if (_isAttaching) return;

    final clean = BarcodeUtils.sanitize(rawBarcode);
    dev.log('[BulkAssign] Step 1: Processing barcode raw="$rawBarcode" clean="$clean"', name: 'BulkAssign');

    if (clean.isEmpty) {
      dev.log('[BulkAssign] Clean barcode is empty, ignoring.', name: 'BulkAssign');
      return;
    }

    final allItems = ref.read(barcodeQueueStreamProvider).value ?? [];
    final visibleItems = _filterItems(allItems);

    if (visibleItems.isEmpty || _selectedIndex >= visibleItems.length) {
      dev.log('[BulkAssign] No item selected or queue is empty.', name: 'BulkAssign');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product from the list below first.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final target = visibleItems[_selectedIndex];
    dev.log('[BulkAssign] Step 2: Target product="${target.displayName}" prodId=${target.productId} varId=${target.variantId}', name: 'BulkAssign');

    // Check if this barcode is already attached to THIS exact item
    if (target.barcodes.contains(clean)) {
      dev.log('[BulkAssign] Barcode $clean is already assigned to this item.', name: 'BulkAssign');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode $clean is already assigned to ${target.displayName}'),
            backgroundColor: AppColors.accentAmber,
          ),
        );
      }
      return;
    }

    setState(() => _isAttaching = true);

    try {
      final repo = ref.read(productsRepositoryProvider);

      // Duplicate check across other products/variants
      dev.log('[BulkAssign] Step 3: Checking duplicate barcode across catalog...', name: 'BulkAssign');
      final owner = await repo.getBarcodeOwner(clean, excludeProductId: target.productId);
      if (owner != null) {
        HapticFeedback.vibrate();
        final ownerVariant = owner.variant?.variantName ?? 'Standard';
        final message = 'Already used by ${owner.product.name} ($ownerVariant)';
        dev.log('[BulkAssign] Barcode duplicate conflict: $message', name: 'BulkAssign');

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Assign additional barcode
      dev.log('[BulkAssign] Step 4: Attaching barcode $clean to product ID ${target.productId}...', name: 'BulkAssign');
      await repo.assignBarcodeToProduct(
        productId: target.productId,
        barcode: clean,
        variantId: target.variantId,
      );

      ref.read(barcodeCacheServiceProvider).invalidate();
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();

      dev.log('[BulkAssign] Step 5: Barcode attached successfully!', name: 'BulkAssign');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added barcode $clean to ${target.displayName}'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Advance to next index automatically
        final remainingCount = visibleItems.length;
        if (_selectedSegment == 0) {
          // In "Without barcode" mode, this item will drop out of the list automatically.
          // Keep the same index (which will now point to the next item) or clamp to end.
          if (_selectedIndex >= remainingCount - 1 && remainingCount > 1) {
            _selectedIndex = remainingCount - 2;
          }
        } else {
          // In "All products" mode, advance to next item
          if (_selectedIndex + 1 < remainingCount) {
            _selectedIndex++;
          }
        }
      }
    } catch (e, stack) {
      dev.log('[BulkAssign] Error attaching barcode: $e', error: e, stackTrace: stack, name: 'BulkAssign');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach barcode: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAttaching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final queueAsync = ref.watch(barcodeQueueStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.products),
        title: const Text('Bulk Barcode Assignment'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            tooltip: 'Toggle Torch',
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          dev.log('[BulkAssign] Stream error: $err', error: err, stackTrace: stack, name: 'BulkAssign');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorRed),
                  const SizedBox(height: 12),
                  Text('Failed to load queue: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(barcodeQueueStreamProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (allItems) {
          final withoutBarcodeCount = allItems.where((i) => !i.hasBarcode).length;
          final allCount = allItems.length;
          final visibleItems = _filterItems(allItems);

          if (_selectedIndex >= visibleItems.length && visibleItems.isNotEmpty) {
            _selectedIndex = visibleItems.length - 1;
          }

          final targetItem = visibleItems.isNotEmpty && _selectedIndex < visibleItems.length
              ? visibleItems[_selectedIndex]
              : null;

          return Column(
            children: [
              // 1. Active Target Product Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: targetItem != null
                          ? Text(
                              '${_selectedIndex + 1}',
                              style: AppTypography.heading3.copyWith(color: AppColors.primaryTeal),
                            )
                          : const Icon(Icons.check_rounded, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: targetItem != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetItem.displayName,
                                  style: AppTypography.heading3.copyWith(fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Price: ${Formatters.currency(targetItem.price, symbol: settings.currencySymbol)} • Variant: ${targetItem.variantLabel}',
                                  style: AppTypography.caption,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  targetItem.hasBarcode
                                      ? 'Has ${targetItem.barcodes.length} barcode(s). Scan to add another.'
                                      : 'No barcode yet. Scan pack to attach & advance.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'No products selected. Choose a product below or reset filters.',
                              style: AppTypography.bodyMedium,
                            ),
                    ),
                    if (visibleItems.length > 1)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedIndex = (_selectedIndex + 1) % visibleItems.length;
                        }),
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),

              // 2. Camera Preview with Torch & Zoom
              SizedBox(
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),
                    // Reticle overlay
                    Container(
                      width: 240,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryTeal, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Zoom Slider at bottom of camera
                    Positioned(
                      bottom: 4,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: _zoomScale,
                                  min: 0.0,
                                  max: 1.0,
                                  activeColor: AppColors.primaryTeal,
                                  inactiveColor: Colors.white30,
                                  onChanged: (v) {
                                    setState(() => _zoomScale = v);
                                    _scannerController.setZoomScale(v);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              '${(1 + _zoomScale * 3).toStringAsFixed(1)}x',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isAttaching)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryTeal),
                        ),
                      ),
                  ],
                ),
              ),

              // 3. Segmented Control & Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text('Without barcode ($withoutBarcodeCount)'),
                          icon: const Icon(Icons.label_off_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('All products ($allCount)'),
                          icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        ),
                      ],
                      selected: {_selectedSegment},
                      onSelectionChanged: (set) {
                        setState(() {
                          _selectedSegment = set.first;
                          _selectedIndex = 0;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products or barcodes...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Products Queue / Catalog List
              Expanded(
                child: visibleItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedSegment == 0
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.search_off_rounded,
                                size: 48,
                                color: _selectedSegment == 0 ? AppColors.successGreen : Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedSegment == 0
                                    ? 'All products have barcodes!'
                                    : 'No products match search.',
                                style: AppTypography.heading3,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedSegment == 0
                                    ? 'Switch to "All products" to add multiple barcodes.'
                                    : 'Try a different search query.',
                                style: AppTypography.caption,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          final isSelected = index == _selectedIndex;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.08),
                            leading: Icon(
                              isSelected
                                  ? Icons.play_arrow_rounded
                                  : (item.hasBarcode ? Icons.qr_code_2_rounded : Icons.label_off_outlined),
                              color: isSelected
                                  ? AppColors.primaryTeal
                                  : (item.hasBarcode ? Colors.grey : AppColors.accentAmber),
                            ),
                            title: Text(
                              item.displayName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  'Price: ${Formatters.currency(item.price, symbol: settings.currencySymbol)} • ${item.variantLabel}',
                                  style: AppTypography.caption,
                                ),
                                const SizedBox(height: 4),
                                if (item.barcodes.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: item.barcodes
                                        .map((bc) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                bc,
                                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                              ),
                                            ))
                                        .toList(),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'No barcode',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.accentAmber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 20)
                                : null,
                            onTap: () => setState(() => _selectedIndex = index),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
