import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/database_provider.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/services/share_intent_service.dart';
import 'features/backup/services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background auto-backup worker
  try {
    await Workmanager().initialize(callbackDispatcher);
  } catch (e) {
    debugPrint('Workmanager init: $e');
  }

  // Low-end device optimization: lock orientation to portrait for POS handheld stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cap image cache for low-RAM devices (Poco C51 2GB RAM: max 15 MB, 50 images)
  PaintingBinding.instance.imageCache.maximumSize = 50; // Max 50 decoded bitmaps
  PaintingBinding.instance.imageCache.maximumSizeBytes = 15 * 1024 * 1024; // 15 MB hard cap

  // Listen to native memory pressure (onTrimMemory / onLowMemory) and purge caches
  const MethodChannel('com.shopmate.pos/device_info').setMethodCallHandler((call) async {
    if (call.method == 'onMemoryPressure') {
      debugPrint('[ShopmateMemory] Native memory pressure signal received. Purging image caches.');
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
  });

  runApp(
    const ProviderScope(
      child: ShopmateApp(),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ShopmateApp extends ConsumerStatefulWidget {
  const ShopmateApp({super.key});

  @override
  ConsumerState<ShopmateApp> createState() => _ShopmateAppState();
}

class _ShopmateAppState extends ConsumerState<ShopmateApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      ShareIntentService.initialize(
        onImageReceived: (imagePath) {
          router.push(AppRoutes.productAdd, extra: imagePath);
        },
      );
    });
  }

  @override
  void dispose() {
    ShareIntentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Shopmate',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: settings.showPerformanceOverlay,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme(seedColor: settings.accentColor),
      darkTheme: AppTheme.darkTheme(seedColor: settings.accentColor),
      routerConfig: router,
    );
  }
}
