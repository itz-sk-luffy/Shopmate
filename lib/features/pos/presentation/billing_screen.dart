import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/utils/barcode_utils.dart';
import '../../../core/utils/image_helper.dart';
import '../../products/data/products_repository.dart';
import '../data/billing_repository.dart';
import 'providers/cart_provider.dart';
import 'widgets/weight_input_sheet.dart';
import 'widgets/custom_item_dialog.dart';
import 'widgets/customer_select_dialog.dart';
import 'widgets/held_bills_sheet.dart';
import 'widgets/cart_items_sheet.dart';
import 'widgets/fast_scan_sheet.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  final List<({String char, int timeMs})> _keyBurstBuffer = [];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _searchController.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_keyBurstBuffer.isNotEmpty) {
          // Check if characters arrived in rapid burst (< 50 ms apart)
          bool isBurst = true;
          for (int i = 1; i < _keyBurstBuffer.length; i++) {
            if (_keyBurstBuffer[i].timeMs - _keyBurstBuffer[i - 1].timeMs > 50) {
              isBurst = false;
              break;
            }
          }

          final code = _keyBurstBuffer.map((e) => e.char).join();
          _keyBurstBuffer.clear();

          if (isBurst && code.isNotEmpty) {
            // Remove scanned characters from search field if it had focus
            if (_searchController.text.endsWith(code)) {
              _searchController.text = _searchController.text.substring(
                0,
                _searchController.text.length - code.length,
              );
            }
            _processBarcode(code);
            return true;
          }
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_keyBurstBuffer.isNotEmpty && (now - _keyBurstBuffer.last.timeMs) > 100) {
          _keyBurstBuffer.clear();
        }
        _keyBurstBuffer.add((char: event.character!, timeMs: now));
      }
    }
    return false;
  }

  void _processBarcode(String barcode) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final clean = BarcodeUtils.sanitize(barcode);
    if (clean.isEmpty) return;

    final cacheService = ref.read(barcodeCacheServiceProvider);
    final match = await cacheService.findByBarcode(clean);

    if (!mounted) return;

    if (match != null) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.lightImpact();

      final isWeightItem = match.product.unit == 'kg' ||
          match.product.unit == 'ltr' ||
          match.product.unit == 'gm' ||
          match.product.unit == 'ml';

      if (isWeightItem) {
        _openWeightSheet(match.product);
      } else {
        ref.read(cartProvider.notifier).addItem(match.product);
        final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
        debugPrint('[ScanTiming] Scan to cart updated in ${elapsed}ms for ${match.product.name}');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${match.displayName} to bill (${elapsed}ms)'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      HapticFeedback.vibrate();
      await cacheService.logUnmatchedScan(clean);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for barcode: $clean (logged)'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FastScanSheet(),
    );
  }

  void _openWeightSheet(Product product) {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => WeightInputSheet(
        product: product,
        currencySymbol: settings.currencySymbol,
        onAdd: (qty) {
          ref.read(cartProvider.notifier).addItem(product, quantity: qty);
        },
      ),
    );
  }

  void _holdCurrentBill() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Nothing to hold.')),
      );
      return;
    }

    try {
      final billingRepo = ref.read(billingRepositoryProvider);
      final heldBill = await billingRepo.holdBill(cart);
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill held as ${heldBill.billNumber}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not hold bill: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _openHeldBillsSheet() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => HeldBillsSheet(currencySymbol: settings.currencySymbol),
    );
  }

  void _openCustomerPicker() {
    final settings = ref.read(settingsProvider);
    final cart = ref.read(cartProvider);
    showDialog(
      context: context,
      builder: (ctx) => CustomerSelectDialog(
        currentCustomer: cart.selectedCustomer,
        currencySymbol: settings.currencySymbol,
        onSelected: (customer) {
          ref.read(cartProvider.notifier).setCustomer(customer);
        },
      ),
    );
  }

  void _openCustomItemDialog() {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (ctx) => CustomItemDialog(
        defaultGstRate: settings.gstEnabled ? settings.taxRateDefault : 0.0,
        isGstEnabled: settings.gstEnabled,
        onAdd: ({
          required String name,
          required double price,
          required double quantity,
          required String unit,
          required double gstRate,
          required bool isDecimalAllowed,
          int? categoryId,
          String? barcode,
          bool saveToCatalog = false,
        }) async {
          if (saveToCatalog) {
            try {
              final repo = ref.read(productsRepositoryProvider);
              final newId = await repo.addProduct(
                ProductsCompanion.insert(
                  name: name,
                  price: price,
                  gstRate: drift.Value(gstRate),
                  unit: drift.Value(unit),
                  categoryId: drift.Value(categoryId),
                  barcode: drift.Value(barcode),
                ),
              );
              ref.invalidate(productsListStreamProvider);
              ref.invalidate(categoryProductCountsStreamProvider);
              ref.read(barcodeCacheServiceProvider).invalidate();
              final newProd = await repo.getProductById(newId);
              if (newProd != null) {
                ref.read(cartProvider.notifier).addItem(newProd, quantity: quantity);
                return;
              }
            } catch (e) {
              debugPrint('Error saving custom item to catalog: $e');
            }
          }

          ref.read(cartProvider.notifier).addCustomItem(
            name: name,
            price: price,
            quantity: quantity,
            unit: unit,
            gstRate: gstRate,
            isDecimalAllowed: isDecimalAllowed,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final selectedCustomer = ref.watch(cartProvider.select((c) => c.selectedCustomer));
    final hasCartItems = ref.watch(cartProvider.select((c) => c.items.isNotEmpty));
    final heldBillsAsync = ref.watch(heldBillsStreamProvider);
    final heldCount = heldBillsAsync.value?.length ?? 0;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(
      productsListStreamProvider((
        categoryId: _selectedCategoryId,
        search: _searchController.text.trim(),
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              selectedCustomer != null
                  ? 'Customer: ${selectedCustomer.name}'
                  : 'Walk-in Customer',
              style: AppTypography.caption.copyWith(
                color: selectedCustomer != null
                    ? theme.colorScheme.primary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
        actions: [
          // Customer selection button
          IconButton(
            icon: Icon(
              selectedCustomer != null ? Icons.person_rounded : Icons.person_add_outlined,
              color: selectedCustomer != null ? theme.colorScheme.primary : null,
            ),
            tooltip: selectedCustomer != null ? 'Change Customer' : 'Attach Customer',
            onPressed: _openCustomerPicker,
          ),
          // Hold Bill button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.pause_circle_outline_rounded),
                tooltip: heldCount > 0 ? 'View Held Bills ($heldCount)' : 'Hold Current Bill',
                onPressed: () {
                  if (heldCount > 0 && !hasCartItems) {
                    _openHeldBillsSheet();
                  } else {
                    _holdCurrentBill();
                  }
                },
              ),
              if (heldCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: _openHeldBillsSheet,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accentAmber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$heldCount',
                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Quick Custom Item
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add Custom Item',
            onPressed: _openCustomItemDialog,
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'held') {
                _openHeldBillsSheet();
              } else if (val == 'clear') {
                ref.read(cartProvider.notifier).clearCart();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'held',
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Held Bills ($heldCount)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded, size: 18, color: AppColors.errorRed),
                    SizedBox(width: 8),
                    Text('Clear Bill', style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar + Camera Scanner Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product or barcode...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _openCameraScanner,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Chips Row
          categoriesAsync.when(
            data: (categories) {
              if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedCategoryId = null);
                });
              }
              return SizedBox(
                height: 40,
                child: ListView.separated(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  cacheExtent: 200.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == null;
                      return ChoiceChip(
                        label: const Text('All Items'),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategoryId = null);
                        },
                      );
                    }
                    final cat = categories[index - 1];
                    final isSelected = _selectedCategoryId == cat.id;
                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategoryId = val ? cat.id : null;
                        });
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),
          const SizedBox(height: 8),

          // Product Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text('No products found', style: AppTypography.captionBold),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  cacheExtent: 200.0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(
                      context,
                      product: product,
                      currency: settings.currencySymbol,
                      isDark: isDark,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading products: $err')),
            ),
          ),

          // Sticky Bottom Cart Bar
          _StickyBottomCartBar(
            currencySymbol: settings.currencySymbol,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required Product product,
    required String currency,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final isWeightItem = product.unit == 'kg' ||
        product.unit == 'ltr' ||
        product.unit == 'gm' ||
        product.unit == 'ml';

    final cartQty = ref.watch(cartProvider.select((c) {
      final idx = c.items.indexWhere((it) => it.productId == product.id);
      return idx >= 0 ? c.items[idx].quantity : 0.0;
    }));

    return RepaintBoundary(
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (isWeightItem) {
              _openWeightSheet(product);
            } else {
              ref.read(cartProvider.notifier).addItem(product);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image or Icon with live quantity bubble badge
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: product.imagePath != null && File(product.imagePath!).existsSync()
                            ? Builder(builder: (_) {
                                final thumb = ImageHelper.getThumbnailPath(product.imagePath!);
                                final imgPath = File(thumb).existsSync() ? thumb : product.imagePath!;
                                return Image.file(
                                  File(imgPath),
                                  fit: BoxFit.cover,
                                  cacheWidth: 150,
                                  cacheHeight: 150,
                                  filterQuality: FilterQuality.low,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 26,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                  ),
                                );
                              })
                            : Icon(
                                Icons.shopping_bag_outlined,
                                size: 26,
                                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              ),
                      ),
                      if (cartQty > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              cartQty.truncateToDouble() == cartQty
                                  ? cartQty.toInt().toString()
                                  : (cartQty * 10 % 1 == 0
                                      ? cartQty.toStringAsFixed(1)
                                      : cartQty.toStringAsFixed(2)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.currency(product.price, symbol: currency),
                      style: AppTypography.priceBold.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '/${product.unit}',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
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

class _StickyBottomCartBar extends ConsumerWidget {
  final String currencySymbol;
  final bool isDark;

  const _StickyBottomCartBar({
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartSummary = ref.watch(cartProvider.select((c) => (
      itemCount: c.itemCount,
      grandTotal: c.grandTotal,
      hasItems: c.items.isNotEmpty,
    )));

    if (!cartSummary.hasItems) {
      return const SizedBox.shrink();
    }

    final formattedTotal = Formatters.currency(cartSummary.grandTotal, symbol: currencySymbol);

    final itemText = '${cartSummary.itemCount} ${cartSummary.itemCount == 1 ? 'Item' : 'Items'}';
    final buttonLabel = 'View Cart ($itemText) • $formattedTotal';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Isolate touches from background grid
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => CartItemsSheet(currencySymbol: currencySymbol),
                  );
                },
                icon: Badge(
                  label: Text(
                    '${cartSummary.itemCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF0F766E),
                  child: const Icon(Icons.shopping_cart_rounded, size: 20),
                ),
                label: Text(
                  buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
