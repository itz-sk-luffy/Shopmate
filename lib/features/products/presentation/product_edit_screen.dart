import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/services/open_food_facts_service.dart';
import '../../../core/utils/barcode_utils.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../data/products_repository.dart';
import 'web_image_picker_screen.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  final int? productId;
  final String? initialImagePath;

  const ProductEditScreen({
    super.key,
    this.productId,
    this.initialImagePath,
  });

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();

  String _selectedUnit = 'pcs';
  int? _selectedCategoryId;
  double _selectedGstRate = 0.0;
  String? _imagePath;
  bool _isFavorite = false;

  bool _isDuplicateBarcode = false;
  ({Product product, ProductVariant? variant})? _duplicateOwner;
  BarcodeValidationResult? _barcodeValidation;
  bool _isLoading = true;
  bool _isAutofilling = false;
  Timer? _autofillDebounce;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
    _barcodeController.addListener(_onBarcodeChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _autofillDebounce?.cancel();
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.removeListener(_onBarcodeChanged);
    _barcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      final repo = ref.read(productsRepositoryProvider);
      final validation = BarcodeUtils.validate(barcode);
      final owner = await repo.getBarcodeOwner(barcode, excludeProductId: widget.productId);
      if (mounted) {
        setState(() {
          _barcodeValidation = validation.isValid ? null : validation;
          _duplicateOwner = owner;
          _isDuplicateBarcode = owner != null;
        });
      }

      // Check Open Food Facts autofill with debounce if online autofill setting is on
      final settings = ref.read(settingsProvider);
      if (settings.barcodeAutofillOnline && (widget.productId == null || _nameController.text.trim().isEmpty)) {
        if (barcode.length >= 8) {
          _autofillDebounce?.cancel();
          _autofillDebounce = Timer(const Duration(milliseconds: 350), () {
            if (mounted && _barcodeController.text.trim() == barcode) {
              _checkOpenFoodFactsAutofill(barcode);
            }
          });
        }
      }
    } else {
      _autofillDebounce?.cancel();
      if (_isDuplicateBarcode || _barcodeValidation != null) {
        setState(() {
          _isDuplicateBarcode = false;
          _duplicateOwner = null;
          _barcodeValidation = null;
        });
      }
    }
  }

  void _checkOpenFoodFactsAutofill(String barcode) async {
    if (_isAutofilling) return;
    setState(() => _isAutofilling = true);

    try {
      final offProduct = await OpenFoodFactsService.lookup(barcode);
      if (!mounted) return;

      if (offProduct != null) {
        _nameController.text = offProduct.displayName;
        if (offProduct.imageUrl != null) {
          final cachedPath = await OpenFoodFactsService.downloadAndCacheImage(offProduct.imageUrl!, barcode);
          if (cachedPath != null && mounted) {
            setState(() => _imagePath = cachedPath);
          }
        }
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text('Auto-filled: ${offProduct.displayName}'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          controller.close();
        });
      } else {
        if (barcode.length >= 8) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          final controller = messenger.showSnackBar(
            SnackBar(
              content: const Text('Barcode not found in online databases'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Search Web',
                textColor: AppColors.accentAmber,
                onPressed: _openWebImagePicker,
              ),
            ),
          );
          Future.delayed(const Duration(seconds: 4), () {
            controller.close();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAutofilling = false);
      }
    }
  }

  void _generateBarcode() async {
    final repo = ref.read(productsRepositoryProvider);
    final code = await repo.generateInternalBarcode();
    _barcodeController.text = code;
    HapticFeedback.lightImpact();
  }

  Future<void> _loadInitialData() async {
    final repo = ref.read(productsRepositoryProvider);
    final categories = await repo.getCategories();
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    if (widget.productId != null) {
      final product = await repo.getProductById(widget.productId!);
      if (product != null) {
        _nameController.text = product.name;
        _priceController.text = product.price.toStringAsFixed(2);
        _barcodeController.text = product.barcode ?? '';
        _selectedUnit = product.unit;
        _selectedCategoryId = product.categoryId ?? _selectedCategoryId;
        _selectedGstRate = product.gstRate;
        _imagePath = product.imagePath ?? _imagePath;
        _isFavorite = product.isFavorite;
      }
    } else {
      final settings = ref.read(settingsProvider);
      _selectedGstRate = settings.gstEnabled ? settings.taxRateDefault : 0.0;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 600, imageQuality: 85);
      if (picked != null) {
        final savedPath = await ImageHelper.compressAndSaveLocalImage(
          picked.path,
          productId: widget.productId,
          oldImagePath: _imagePath,
        );
        PaintingBinding.instance.imageCache.evict(FileImage(File(savedPath)));
        setState(() => _imagePath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _openWebImagePicker() async {
    final nameQuery = _nameController.text.trim();
    final barcodeQuery = _barcodeController.text.trim();
    final query = nameQuery.isNotEmpty ? nameQuery : barcodeQuery;
    final settings = ref.read(settingsProvider);

    final selectedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => WebImagePickerScreen(
          initialQuery: query,
          searchEngine: settings.searchEngine,
          productId: widget.productId,
          currentImagePath: _imagePath,
        ),
      ),
    );

    if (selectedPath != null && mounted) {
      PaintingBinding.instance.imageCache.evict(FileImage(File(selectedPath)));
      setState(() => _imagePath = selectedPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image updated successfully')),
      );
    }
  }

  Future<void> _openBarcodeScannerModal() async {
    final scannedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const ProductBarcodeScannerSheet(),
    );
    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _autofillDebounce?.cancel();
      setState(() {
        _barcodeController.text = scannedCode;
      });
      // Immediately trigger autofill without waiting for debounce
      final settings = ref.read(settingsProvider);
      if (settings.barcodeAutofillOnline && (widget.productId == null || _nameController.text.trim().isEmpty)) {
        _checkOpenFoodFactsAutofill(scannedCode);
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();

    final repo = ref.read(productsRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final effectiveGstRate = !settings.gstEnabled
        ? 0.0
        : (widget.productId == null
            ? settings.taxRateDefault
            : (_selectedGstRate > 0 ? _selectedGstRate : settings.taxRateDefault));

    if (widget.productId == null) {
      await repo.addProduct(ProductsCompanion.insert(
        name: name,
        price: price,
        gstRate: drift.Value(effectiveGstRate),
        unit: drift.Value(_selectedUnit),
        categoryId: drift.Value(_selectedCategoryId),
        barcode: drift.Value(barcode),
        imagePath: drift.Value(_imagePath),
        isFavorite: drift.Value(_isFavorite),
      ));
    } else {
      await repo.updateProduct(ProductsCompanion(
        id: drift.Value(widget.productId!),
        name: drift.Value(name),
        price: drift.Value(price),
        gstRate: drift.Value(effectiveGstRate),
        unit: drift.Value(_selectedUnit),
        categoryId: drift.Value(_selectedCategoryId),
        barcode: drift.Value(barcode),
        imagePath: drift.Value(_imagePath),
        isFavorite: drift.Value(_isFavorite),
        updatedAt: drift.Value(DateTime.now()),
      ));
    }

    // Invalidate product & queue providers so every screen immediately reflects changes
    ref.invalidate(productsListStreamProvider);
    ref.invalidate(barcodeQueueStreamProvider);
    ref.read(barcodeCacheServiceProvider).invalidate();
    if (_imagePath != null) {
      PaintingBinding.instance.imageCache.evict(FileImage(File(_imagePath!)));
      final thumb = File(ImageHelper.getThumbnailPath(_imagePath!));
      if (thumb.existsSync()) {
        PaintingBinding.instance.imageCache.evict(FileImage(thumb));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.productId == null ? 'Product added successfully' : 'Product updated'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isEditing = widget.productId != null;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final unitsAsync = ref.watch(unitsStreamProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.products),
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
            color: _isFavorite ? AppColors.accentAmber : null,
            tooltip: 'Favorite Item',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save',
            onPressed: _saveProduct,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker Section
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      child: _imagePath != null && File(_imagePath!).existsSync()
                          ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                          : Icon(Icons.inventory_2_outlined, size: 36, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _openWebImagePicker,
                              icon: const Icon(Icons.search_rounded, size: 16),
                              label: const Text('Online Search', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(110, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 16),
                              label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, size: 16),
                              label: const Text('Camera', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                            if (_imagePath != null)
                              TextButton(
                                onPressed: () => setState(() => _imagePath = null),
                                child: const Text('Remove Image', style: TextStyle(color: AppColors.errorRed, fontSize: 11)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product Details
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Product Details', style: AppTypography.section),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g. Tata Salt 1kg',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Product name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price (${settings.currencySymbol}) *',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter price';
                            if (double.tryParse(val.trim()) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: unitsAsync.when(
                          data: (units) {
                            return DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: units.map((u) {
                                return DropdownMenuItem(value: u.code, child: Text(u.code));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedUnit = val);
                              },
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  categoriesAsync.when(
                    data: (categories) {
                      final hasMatch = categories.any((c) => c.id == _selectedCategoryId);
                      final currentVal = hasMatch ? _selectedCategoryId : (categories.isNotEmpty ? categories.first.id : null);
                      return DropdownButtonFormField<int>(
                        value: currentVal,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: categories.map((c) {
                          return DropdownMenuItem(value: c.id, child: Text(c.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategoryId = val);
                        },
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Barcode Section
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Barcode / Scan', style: AppTypography.section),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Barcode Number',
                            hintText: 'Enter or scan barcode',
                            prefixIcon: const Icon(Icons.qr_code_rounded),
                            suffixIcon: _isAutofilling
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _generateBarcode,
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        tooltip: 'Generate sequential barcode',
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonalIcon(
                        onPressed: _openBarcodeScannerModal,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scan'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 48),
                        ),
                      ),
                    ],
                  ),
                  if (_barcodeValidation != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.infoBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notice: ${_barcodeValidation!.warning} (saving allowed)',
                              style: AppTypography.caption.copyWith(color: AppColors.infoBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_duplicateOwner != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.accentAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Already used by ${_duplicateOwner!.product.name}${_duplicateOwner!.variant != null && _duplicateOwner!.variant!.variantName != "Standard" ? " (${_duplicateOwner!.variant!.variantName})" : ""}',
                              style: AppTypography.captionBold.copyWith(color: AppColors.accentAmber),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductEditScreen(productId: _duplicateOwner!.product.id),
                                ),
                              );
                            },
                            child: const Text('Open that product'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Product Button
            FilledButton(
              onPressed: _saveProduct,
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: Text(isEditing ? 'Update Product' : 'Add Product to Catalog'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductBarcodeScannerSheet extends StatefulWidget {
  const ProductBarcodeScannerSheet({super.key});

  @override
  State<ProductBarcodeScannerSheet> createState() => _ProductBarcodeScannerSheetState();
}

class _ProductBarcodeScannerSheetState extends State<ProductBarcodeScannerSheet> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isTorchOn = false;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 300,
      cameraResolution: const Size(640, 480),
      returnImage: false,
    );
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchOn = !_isTorchOn;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Column(
        children: [
          AppBar(
            title: const Text('Scan Product Barcode'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Toggle Flash',
                icon: Icon(
                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isTorchOn ? AppColors.warningAmber : null,
                ),
                onPressed: _toggleTorch,
              ),
            ],
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_hasDetected) return;
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null && code.isNotEmpty) {
                    _hasDetected = true;
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, code);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
