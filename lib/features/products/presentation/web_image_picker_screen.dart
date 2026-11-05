import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_helper.dart';
import 'web_image_search_constants.dart';

/// Parsed image representation holding either decoded base64 bytes or a network URL.
class WebImageItem {
  final String raw;
  final bool isBase64;
  final Uint8List? bytes;
  final String? url;

  const WebImageItem._({
    required this.raw,
    required this.isBase64,
    this.bytes,
    this.url,
  });

  factory WebImageItem.fromRaw(String raw) {
    var clean = raw.trim();
    if (clean.startsWith('//')) {
      clean = 'https:$clean';
    }

    if (clean.startsWith('data:image')) {
      try {
        final commaIdx = clean.indexOf(',');
        final b64 = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
        final cleanB64 = b64.replaceAll('\n', '').replaceAll('\r', '').trim();
        final decoded = base64Decode(cleanB64);
        return WebImageItem._(
          raw: clean,
          isBase64: true,
          bytes: decoded,
        );
      } catch (_) {
        // Fallback to URL if decoding fails
      }
    }

    return WebImageItem._(
      raw: clean,
      isBase64: false,
      url: clean,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebImageItem && runtimeType == other.runtimeType && raw == other.raw;

  @override
  int get hashCode => raw.hashCode;
}

enum ImagePickerState {
  idle, // generic/empty query, keyboard focused
  loading, // shimmer grid, polling 500ms
  results, // images loaded
  empty, // 10s elapsed with 0 results
  captcha, // bot block / captcha detected
  offline, // network error
}

class WebImagePickerScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  final String searchEngine; // 'google', 'bing', 'duckduckgo'
  final int? productId;
  final String? currentImagePath;

  const WebImagePickerScreen({
    super.key,
    required this.initialQuery,
    this.searchEngine = 'google',
    this.productId,
    this.currentImagePath,
  });

  @override
  ConsumerState<WebImagePickerScreen> createState() => _WebImagePickerScreenState();
}

class _WebImagePickerScreenState extends ConsumerState<WebImagePickerScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _queryController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late AnimationController _shimmerController;

  InAppWebViewController? _webViewController;
  late String _currentEngine;

  final List<WebImageItem> _images = [];
  WebImageItem? _selectedItem;
  bool _isProcessing = false;

  ImagePickerState _pickerState = ImagePickerState.loading;
  String _errorMessage = '';
  bool _isFullBrowserMode = false;
  bool _isLoadingMore = false;

  Timer? _pollTimer;
  int _pollCount = 0;

  static const Color _darkSurface = Color(0xFF0B1215);
  static const Color _lightSurface = Color(0xFFF7F9FA);

  @override
  void initState() {
    super.initState();
    _currentEngine = widget.searchEngine;
    _scrollController = ScrollController()..addListener(_onScroll);
    _focusNode = FocusNode();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    final rawInitial = widget.initialQuery.trim();
    final isGeneric = rawInitial.isEmpty ||
        rawInitial.toLowerCase() == 'new product' ||
        rawInitial.toLowerCase() == 'product';

    if (isGeneric) {
      _queryController = TextEditingController(text: '');
      _pickerState = ImagePickerState.idle;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } else {
      _queryController = TextEditingController(text: rawInitial);
      _pickerState = ImagePickerState.loading;
      _startPollingSearch();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _queryController.dispose();
    _focusNode.dispose();
    _shimmerController.dispose();
    _webViewController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 200 &&
        _pickerState == ImagePickerState.results &&
        !_isLoadingMore &&
        _images.length < WebImageSearchConstants.maxGridImages) {
      _loadMoreImages();
    }
  }

  void _startPollingSearch() {
    _pollTimer?.cancel();
    _pollCount = 0;

    // Start 500ms polling for up to 10 seconds (20 iterations)
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      _pollCount++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      final controller = _webViewController;
      if (controller == null) return;

      // 1. Check CAPTCHA / bot block
      try {
        final currentUrl = (await controller.getUrl())?.toString() ?? '';
        if (currentUrl.contains('/sorry/') || currentUrl.contains('sorry.google')) {
          timer.cancel();
          setState(() {
            _pickerState = ImagePickerState.captcha;
            _errorMessage = 'Google asked for verification. Switch to Bing?';
          });
          return;
        }

        final isCaptcha = await controller.evaluateJavascript(source: """
          (function() {
            var t = (document.body ? (document.body.innerText || document.body.textContent) : '') || '';
            return t.indexOf('unusual traffic') !== -1 || t.indexOf('recaptcha') !== -1;
          })();
        """);
        if (isCaptcha == true) {
          timer.cancel();
          setState(() {
            _pickerState = ImagePickerState.captcha;
            _errorMessage = 'Google asked for verification. Switch to Bing?';
          });
          return;
        }
      } catch (_) {}

      // 2. Run extraction
      try {
        await _extractImages(controller);
      } catch (_) {}

      // 3. Timeout check after 10 seconds (20 polls)
      if (_pollCount >= 20) {
        timer.cancel();
        if (_images.isEmpty && mounted && _pickerState == ImagePickerState.loading) {
          setState(() {
            _pickerState = ImagePickerState.empty;
            if (_currentEngine == 'google') {
              _errorMessage = 'Google returned no images. Try Bing';
            } else {
              _errorMessage = 'No image results found for "${_queryController.text.trim()}".';
            }
          });
        }
      }
    });
  }

  void _performSearch() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      _pollTimer?.cancel();
      setState(() {
        _images.clear();
        _selectedItem = null;
        _pickerState = ImagePickerState.idle;
      });
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _images.clear();
      _selectedItem = null;
      _pickerState = ImagePickerState.loading;
      _errorMessage = '';
      _isFullBrowserMode = false;
      _isLoadingMore = false;
    });

    _startPollingSearch();

    final searchUrl = WebImageSearchConstants.buildSearchUrl(_currentEngine, query);
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(searchUrl)),
    );
  }

  void _switchEngine(String newEngine) {
    if (_currentEngine == newEngine) return;
    setState(() {
      _currentEngine = newEngine;
    });
    ref.read(databaseProvider).setSetting('search_engine', newEngine);
    _performSearch();
  }

  void _loadMoreImages() {
    if (_webViewController == null ||
        _isLoadingMore ||
        _images.length >= WebImageSearchConstants.maxGridImages) {
      return;
    }

    setState(() => _isLoadingMore = true);

    _webViewController!.evaluateJavascript(
      source: WebImageSearchConstants.getScrollAndExtractScript(
        engine: _currentEngine,
        handlerName: 'loadMore',
        maxCount: WebImageSearchConstants.batchImageLimit,
      ),
    );
  }

  Future<void> _handleConsentBypass(InAppWebViewController controller, WebUri? url) async {
    if (url != null && (url.toString().contains('consent.google') || url.toString().contains('consent'))) {
      await controller.evaluateJavascript(
        source: WebImageSearchConstants.consentBypassScript,
      );
    }
  }

  Future<void> _extractImages(InAppWebViewController controller) async {
    if (_isFullBrowserMode) return;

    await controller.evaluateJavascript(
      source: WebImageSearchConstants.getExtractionScript(
        engine: _currentEngine,
        handlerName: 'onImages',
        maxCount: WebImageSearchConstants.batchImageLimit,
      ),
    );
  }

  void _onImagesExtracted(List<dynamic> rawUrls, {bool isAppend = false}) {
    final Set<String> existingRaws = _images.map((e) => e.raw).toSet();
    final List<WebImageItem> newItems = [];

    for (final raw in rawUrls) {
      if (raw is String && raw.length > 10 && !existingRaws.contains(raw)) {
        existingRaws.add(raw);
        newItems.add(WebImageItem.fromRaw(raw));
      }
    }

    if (!mounted) return;

    if (newItems.isNotEmpty || _images.isNotEmpty) {
      _pollTimer?.cancel();
      setState(() {
        _isLoadingMore = false;
        if (isAppend) {
          final remaining = WebImageSearchConstants.maxGridImages - _images.length;
          if (remaining > 0) {
            _images.addAll(newItems.take(remaining));
          }
        } else {
          _images.addAll(newItems.take(WebImageSearchConstants.maxGridImages));
        }
        _pickerState = ImagePickerState.results;
      });
    }
  }

  void _openFullBrowserMode() {
    _pollTimer?.cancel();
    setState(() {
      _isFullBrowserMode = true;
      _pickerState = ImagePickerState.results;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceHex = isDark ? '#0B1215' : '#F7F9FA';

    _webViewController?.injectCSSCode(
      source: WebImageSearchConstants.getHideCss(_currentEngine, surfaceHex),
    );
    _webViewController?.evaluateJavascript(
      source: WebImageSearchConstants.tapSelectionScript,
    );
  }

  Future<void> _handleImageConfirm(WebImageItem item) async {
    if (_isProcessing) return;

    dev.log('[WebImagePicker] Step 1: User selected image tile (raw length: ${item.raw.length})', name: 'WebImagePicker');
    setState(() {
      _selectedItem = item;
      _isProcessing = true;
    });

    try {
      final localPath = await ImageHelper.processAndSaveWebImage(
        item.raw,
        productId: widget.productId,
        oldImagePath: widget.currentImagePath,
      );
      dev.log('[WebImagePicker] Step 5: Finished saving image to $localPath. Popping...', name: 'WebImagePicker');
      if (!mounted) return;
      Navigator.pop(context, localPath);
    } catch (e, stack) {
      dev.log('[WebImagePicker] Error processing image: $e', error: e, stackTrace: stack, name: 'WebImagePicker');
      if (!mounted) return;
      setState(() {
        _selectedItem = null;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't download this image. Please try another."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickFromGalleryFallback() async {
    if (_isProcessing) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (picked != null) {
        setState(() => _isProcessing = true);
        final localPath = await ImageHelper.compressAndSaveLocalImage(
          picked.path,
          productId: widget.productId,
          oldImagePath: widget.currentImagePath,
        );
        if (mounted) {
          Navigator.pop(context, localPath);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromCameraFallback() async {
    if (_isProcessing) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 600);
      if (picked != null) {
        setState(() => _isProcessing = true);
        final localPath = await ImageHelper.compressAndSaveLocalImage(
          picked.path,
          productId: widget.productId,
          oldImagePath: widget.currentImagePath,
        );
        if (mounted) {
          Navigator.pop(context, localPath);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? _darkSurface : _lightSurface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Hidden WebView (kept offscreen in clean grid mode, brought into view in full browser mode)
            if (InAppWebViewPlatform.instance != null)
              Positioned(
                left: _isFullBrowserMode ? 0 : -10000,
              top: _isFullBrowserMode ? 56 : -10000,
              right: _isFullBrowserMode ? 0 : null,
              bottom: _isFullBrowserMode ? 0 : null,
              width: _isFullBrowserMode ? null : 360,
              height: _isFullBrowserMode ? null : 640,
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    WebImageSearchConstants.buildSearchUrl(
                      _currentEngine,
                      _queryController.text,
                    ),
                  ),
                ),
                initialSettings: InAppWebViewSettings(
                  userAgent: WebImageSearchConstants.userAgent,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  supportMultipleWindows: false,
                  javaScriptCanOpenWindowsAutomatically: false,
                  verticalScrollBarEnabled: true,
                  cacheEnabled: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;

                  controller.addJavaScriptHandler(
                    handlerName: 'onImages',
                    callback: (args) {
                      if (args.isNotEmpty && args[0] is List) {
                        _onImagesExtracted(args[0] as List, isAppend: false);
                      }
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'loadMore',
                    callback: (args) {
                      if (args.isNotEmpty && args[0] is List) {
                        _onImagesExtracted(args[0] as List, isAppend: true);
                      }
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'onImageSelected',
                    callback: (args) {
                      if (args.isNotEmpty && args[0] is String) {
                        final raw = args[0] as String;
                        _handleImageConfirm(WebImageItem.fromRaw(raw));
                      }
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  _handleConsentBypass(controller, url);
                },
                onLoadStop: (controller, url) async {
                  await _handleConsentBypass(controller, url);

                  if (_isFullBrowserMode) {
                    final hex = isDark ? '#0B1215' : '#F7F9FA';
                    await controller.injectCSSCode(
                      source: WebImageSearchConstants.getHideCss(_currentEngine, hex),
                    );
                    await controller.evaluateJavascript(
                      source: WebImageSearchConstants.tapSelectionScript,
                    );
                  } else {
                    await _extractImages(controller);
                  }
                },
                onUpdateVisitedHistory: (controller, url, isReload) {
                  _handleConsentBypass(controller, url);
                },
                onReceivedError: (controller, request, error) {
                  _pollTimer?.cancel();
                  setState(() {
                    _pickerState = ImagePickerState.offline;
                    _errorMessage = 'Unable to connect to the internet. Please check your connection.';
                  });
                },
              ),
            ),

            // Clean Native Picker View
            if (!_isFullBrowserMode)
              Column(
                children: [
                  _buildSearchBarRow(theme, isDark),
                  _buildEngineSwitchRow(isDark),
                  Expanded(
                    child: _buildBodyContent(theme, isDark),
                  ),
                  _buildBottomBar(theme, isDark),
                ],
              )
            else
              Column(
                children: [
                  _buildFullBrowserHeader(theme, isDark),
                  const Spacer(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarRow(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C21) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _queryController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search product images...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                  suffixIcon: _queryController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          splashRadius: 16,
                          onPressed: () {
                            _queryController.clear();
                            setState(() {});
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20),
                          splashRadius: 16,
                          onPressed: _performSearch,
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Choose from Gallery',
            onPressed: _isProcessing ? null : _pickFromGalleryFallback,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Take with Camera',
            onPressed: _isProcessing ? null : _pickFromCameraFallback,
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSwitchRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildEngineChip('google', 'Google', isDark),
          const SizedBox(width: 8),
          _buildEngineChip('bing', 'Bing', isDark),
          const SizedBox(width: 8),
          _buildEngineChip('duckduckgo', 'DuckDuckGo', isDark),
        ],
      ),
    );
  }

  Widget _buildEngineChip(String engineKey, String label, bool isDark) {
    final isSelected = _currentEngine == engineKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (val) {
        if (val) _switchEngine(engineKey);
      },
    );
  }

  Widget _buildFullBrowserHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isFullBrowserMode = false),
          ),
          const Expanded(
            child: Text(
              'Tap an image to select',
              style: AppTypography.section,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isFullBrowserMode = false),
            icon: const Icon(Icons.grid_view_rounded, size: 16),
            label: const Text('Back to Grid'),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, bool isDark) {
    switch (_pickerState) {
      case ImagePickerState.idle:
        return _buildIdlePrompt(isDark);
      case ImagePickerState.loading:
        return _buildShimmerGrid(isDark);
      case ImagePickerState.results:
        return _buildImageGrid(theme, isDark);
      case ImagePickerState.empty:
        return _buildEmptyState(theme, isDark);
      case ImagePickerState.captcha:
        return _buildCaptchaState(theme, isDark);
      case ImagePickerState.offline:
        return _buildOfflineState(theme, isDark);
    }
  }

  Widget _buildIdlePrompt(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 56,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Type a product name to search for images',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGalleryFallback,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromCameraFallback,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 15,
      itemBuilder: (_, __) => _buildSingleShimmerTile(isDark),
    );
  }

  Widget _buildSingleShimmerTile(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.35 + (_shimmerController.value * 0.45);
        final baseColor = isDark ? const Color(0xFF1A262E) : const Color(0xFFE2E8F0);
        return Container(
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => _performSearch(),
      color: theme.colorScheme.primary,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _images.length + (_isLoadingMore ? 3 : 0),
        itemBuilder: (context, index) {
          if (index >= _images.length) {
            return _buildSingleShimmerTile(isDark);
          }

          final item = _images[index];
          final isSelected = _selectedItem == item;
          final isTileProcessing = _isProcessing && isSelected;

          return GestureDetector(
            onTap: _isProcessing ? null : () => _handleImageConfirm(item),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C21) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                      border: isTileProcessing
                          ? Border.all(color: theme.colorScheme.primary, width: 2.5)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.isBase64 && item.bytes != null
                          ? Image.memory(
                              item.bytes!,
                              cacheWidth: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildBrokenPlaceholder(isDark),
                            )
                          : Image.network(
                              item.url!,
                              cacheWidth: 300,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return _buildSingleShimmerTile(isDark);
                              },
                              errorBuilder: (_, __, ___) => _buildBrokenPlaceholder(isDark),
                            ),
                    ),
                  ),
                ),
                if (isTileProcessing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrokenPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF131C21) : const Color(0xFFE2E8F0),
      child: Icon(
        Icons.broken_image_outlined,
        size: 24,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'No images found for "${_queryController.text}".',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (_currentEngine == 'google')
                  FilledButton.icon(
                    onPressed: () => _switchEngine('bing'),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Try Bing'),
                  ),
                OutlinedButton.icon(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullBrowserMode,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: const Text('Open in browser'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGalleryFallback,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromCameraFallback,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptchaState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security_rounded,
              size: 48,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(height: 12),
            const Text(
              'Google asked for verification. Switch to Bing?',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _switchEngine('bing'),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Switch to Bing'),
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGalleryFallback,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromCameraFallback,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to connect to the internet. Please check your connection.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGalleryFallback,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromCameraFallback,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Use images you have rights to.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ),
    );
  }
}
