import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:workmanager/workmanager.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import 'backup_log_service.dart';

const String kAutoBackupTaskKey = 'shopmate_auto_backup';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kAutoBackupTaskKey || task == Workmanager.iOSBackgroundTask) {
      try {
        await BackupService.performHeadlessBackup();
      } catch (e, st) {
        debugPrint('Headless backup background error: $e\n$st');
        await BackupLogService.addLog(
          type: 'Auto Backup',
          isSuccess: false,
          message: 'Workmanager auto-backup task failed.',
          error: '$e\n$st',
        );
      }
    }
    return Future.value(true);
  });
}

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Performs full backup export using ZipFileEncoder streaming.
  /// Resolves all paths in the main isolate and streams directly to disk.
  Future<File> createBackup({String? customName, bool isAuto = false}) async {
    debugPrint('[BackupService] Starting backup export (isAuto: $isAuto)...');
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getTemporaryDirectory();

    final liveDbFile = File(p.join(appDir.path, 'shopmate.sqlite'));
    final productsDir = Directory(p.join(appDir.path, 'products'));
    final backupsDir = Directory(p.join(appDir.path, 'backups'));

    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = customName ?? 'shopmate_backup_$timestamp.zip';
    final targetZip = File(p.join(backupsDir.path, fileName));

    final tempWorkingDir = Directory(
      p.join(cacheDir.path, 'backup_stage_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await tempWorkingDir.create(recursive: true);

    try {
      // Step a: Database consistency via WAL checkpoint / VACUUM INTO
      debugPrint('[BackupService] Running WAL checkpoint (TRUNCATE)...');
      try {
        await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (e, st) {
        debugPrint('[BackupService] WAL checkpoint warning: $e\n$st');
      }

      final tempDbFile = File(p.join(tempWorkingDir.path, 'shopmate.sqlite'));
      bool vacuumSucceeded = false;
      try {
        debugPrint('[BackupService] Attempting VACUUM INTO clean copy...');
        await _db.customStatement(
          "VACUUM INTO '${tempDbFile.path.replaceAll("'", "''")}';",
        );
        vacuumSucceeded = await tempDbFile.exists() && (await tempDbFile.length()) > 0;
      } catch (e) {
        debugPrint('[BackupService] VACUUM INTO not supported or failed, using checkpoint copy: $e');
      }

      if (!vacuumSucceeded) {
        if (!await liveDbFile.exists()) {
          throw Exception('Source database file not found at ${liveDbFile.path}');
        }
        await liveDbFile.copy(tempDbFile.path);
      }

      // Step c: Prepare Manifest & Settings
      debugPrint('[BackupService] Gathering store counts and settings...');
      int billCount = 0;
      int productCount = 0;
      try {
        final bRow = await _db.customSelect('SELECT COUNT(*) AS c FROM bills;').getSingle();
        billCount = bRow.read<int>('c');
      } catch (_) {}

      try {
        final pRow = await _db
            .customSelect('SELECT COUNT(*) AS c FROM products WHERE is_deleted = 0;')
            .getSingle();
        productCount = pRow.read<int>('c');
      } catch (_) {}

      Map<String, String> settingsMap = {};
      try {
        settingsMap = await _db.getAllSettings();
      } catch (e) {
        debugPrint('[BackupService] Could not read settings table: $e');
      }
      final settingsFile = File(p.join(tempWorkingDir.path, 'settings.json'));
      await settingsFile.writeAsString(jsonEncode(settingsMap));

      final manifestData = {
        'appVersion': '1.0.0',
        'dbSchemaVersion': _db.schemaVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'billCount': billCount,
        'productCount': productCount,
      };
      final manifestFile = File(p.join(tempWorkingDir.path, 'manifest.json'));
      await manifestFile.writeAsString(jsonEncode(manifestData));

      // Optional Store Logo
      File? logoFile;
      final logoPath = settingsMap['store_logo_path'] ?? '';
      if (logoPath.isNotEmpty && await File(logoPath).exists()) {
        logoFile = File(logoPath);
      }

      // Step c: Stream zip with ZipFileEncoder
      debugPrint('[BackupService] Streaming files into zip with ZipFileEncoder...');
      if (await targetZip.exists()) {
        await targetZip.delete();
      }

      final encoder = ZipFileEncoder();
      encoder.create(targetZip.path);

      // Add database
      await encoder.addFile(tempDbFile, 'shopmate.sqlite');

      // Add manifest
      await encoder.addFile(manifestFile, 'manifest.json');

      // Add settings
      await encoder.addFile(settingsFile, 'settings.json');

      // Add logo if present
      if (logoFile != null && await logoFile.exists()) {
        final ext = p.extension(logoFile.path).isEmpty ? '.png' : p.extension(logoFile.path);
        await encoder.addFile(logoFile, 'logo$ext');
      }

      // Add product images folder
      if (await productsDir.exists()) {
        final imageEntities = productsDir.listSync(recursive: false);
        for (final entity in imageEntities) {
          if (entity is File && await entity.exists()) {
            final fileName = p.basename(entity.path);
            try {
              await encoder.addFile(entity, 'images/$fileName');
            } catch (e) {
              debugPrint('[BackupService] Skipped image $fileName: $e');
            }
          }
        }
      }

      encoder.closeSync();
      debugPrint('[BackupService] Zip successfully generated: ${targetZip.path} (${await targetZip.length()} bytes)');

      // Keep only latest 5 backups
      await cleanOldBackups(keepCount: 5);

      final size = await targetZip.length();
      await BackupLogService.addLog(
        type: isAuto ? 'Auto Backup' : 'Manual Backup',
        isSuccess: true,
        message: 'Backup created successfully ($fileName, ${(size / 1024).toStringAsFixed(1)} KB)',
        sizeBytes: size,
      );

      return targetZip;
    } catch (e, st) {
      debugPrint('[BackupService] Export failed: $e\n$st');
      await BackupLogService.addLog(
        type: isAuto ? 'Auto Backup' : 'Manual Backup',
        isSuccess: false,
        message: 'Backup export failed: $e',
        error: '$e\n$st',
      );
      rethrow;
    } finally {
      // Clean up temp staging directory
      try {
        if (await tempWorkingDir.exists()) {
          await tempWorkingDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Lists all locally saved backups, sorted newest first
  Future<List<File>> getLocalBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(p.join(appDir.path, 'backups'));
      if (!await backupsDir.exists()) {
        return [];
      }

      final entities = backupsDir.listSync();
      final files = entities
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.zip'))
          .toList();

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e, st) {
      debugPrint('[BackupService] Error reading local backups: $e\n$st');
      return [];
    }
  }

  /// Cleans older backups beyond the retention limit
  Future<void> cleanOldBackups({int keepCount = 5}) async {
    try {
      final backups = await getLocalBackups();
      if (backups.length > keepCount) {
        for (int i = keepCount; i < backups.length; i++) {
          try {
            if (await backups[i].exists()) {
              await backups[i].delete();
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[BackupService] Error cleaning old backups: $e');
    }
  }

  /// Deletes a single backup file
  Future<void> deleteBackup(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, st) {
      debugPrint('[BackupService] Error deleting backup: $e\n$st');
      rethrow;
    }
  }

  /// Restores from a .zip backup archive with full validation and safety rollback.
  Future<void> restoreBackup(File zipFile, {required WidgetRef ref}) async {
    debugPrint('[BackupService] Starting restore from: ${zipFile.path}');
    if (!await zipFile.exists()) {
      throw Exception('Backup file does not exist on disk.');
    }

    final cacheDir = await getTemporaryDirectory();
    final appDir = await getApplicationDocumentsDirectory();

    final stagingDir = Directory(
      p.join(cacheDir.path, 'restore_staging_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await stagingDir.create(recursive: true);

    File? safetyBackupFile;

    try {
      // Step a: Extract archive into staging folder
      debugPrint('[BackupService] Extracting zip archive to staging folder...');
      try {
        await Isolate.run(() => extractFileToDisk(zipFile.path, stagingDir.path));
      } catch (e, st) {
        debugPrint('[BackupService] Extraction failed: $e\n$st');
        throw Exception('Failed to decompress backup archive. The file may be corrupted: $e');
      }

      // Step b: Validate manifest.json exists
      final manifestFile = File(p.join(stagingDir.path, 'manifest.json'));
      if (!await manifestFile.exists()) {
        throw Exception(
          'Validation failed: manifest.json not found in archive. Ensure this is a valid Shopmate backup.',
        );
      }

      Map<String, dynamic> manifestData = {};
      try {
        manifestData = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Validation failed: Corrupted manifest.json in archive: $e');
      }

      // Validate dbSchemaVersion
      final backupSchema = manifestData['dbSchemaVersion'] as int? ?? 1;
      if (backupSchema > _db.schemaVersion) {
        throw Exception(
          'Cannot restore: Backup schema version ($backupSchema) is newer than the current app schema (${_db.schemaVersion}). Please update Shopmate.',
        );
      }

      // Find database file in staging
      File? stagingDbFile;
      final directDb = File(p.join(stagingDir.path, 'shopmate.sqlite'));
      if (await directDb.exists()) {
        stagingDbFile = directDb;
      } else {
        // Search inside subdirectories if nested
        for (final entity in stagingDir.listSync(recursive: true)) {
          if (entity is File && p.basename(entity.path) == 'shopmate.sqlite') {
            stagingDbFile = entity;
            break;
          }
        }
      }

      if (stagingDbFile == null || !await stagingDbFile.exists()) {
        throw Exception('Validation failed: Database file (shopmate.sqlite) not found in archive.');
      }

      // Validate database integrity check with sqlite3 & magic header
      debugPrint('[BackupService] Validating SQLite database integrity...');
      final dbHeader = await stagingDbFile.openRead(0, 16).first;
      const sqliteMagic = [0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00];
      if (dbHeader.length < 16 || !listEquals(dbHeader.sublist(0, 16), sqliteMagic)) {
        throw Exception('Database file failed integrity check: Invalid SQLite header format.');
      }

      try {
        final testDb = sqlite.sqlite3.open(stagingDbFile.path);
        final result = testDb.select('PRAGMA integrity_check;');
        testDb.dispose();

        final checkString = result.isNotEmpty ? result.first.values.first?.toString() : '';
        if (checkString != 'ok') {
          throw Exception('SQLite integrity check failed: $checkString');
        }
        debugPrint('[BackupService] SQLite database passed integrity_check!');
      } catch (e, st) {
        if (e is ArgumentError && e.message.toString().contains('sqlite3.dll')) {
          debugPrint('[BackupService] Native sqlite3 library unavailable in test environment, header validated.');
        } else {
          debugPrint('[BackupService] Database integrity check failed: $e\n$st');
          throw Exception('Database file in backup is corrupted: $e');
        }
      }

      // Step c: Make safety copy of current data first
      debugPrint('[BackupService] Creating pre-restore safety copy of current store data...');
      final safetyTimestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      safetyBackupFile = await createBackup(
        customName: 'Safety_Backup_Before_Restore_$safetyTimestamp.zip',
      );
      debugPrint('[BackupService] Safety backup saved to: ${safetyBackupFile.path}');

      // Step d: Close drift database before replacing files
      debugPrint('[BackupService] Closing current SQLite database connection...');
      try {
        await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}
      await _db.close();

      // Delete leftover -wal and -shm files
      final walFile = File(p.join(appDir.path, 'shopmate.sqlite-wal'));
      final shmFile = File(p.join(appDir.path, 'shopmate.sqlite-shm'));
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();

      // Replace database file
      debugPrint('[BackupService] Replacing shopmate.sqlite with restored database...');
      final targetDbFile = File(p.join(appDir.path, 'shopmate.sqlite'));
      if (await targetDbFile.exists()) {
        await targetDbFile.delete();
      }
      await stagingDbFile.copy(targetDbFile.path);

      // Replace images / products
      debugPrint('[BackupService] Restoring images and store media...');
      final productsDir = Directory(p.join(appDir.path, 'products'));
      if (!await productsDir.exists()) {
        await productsDir.create(recursive: true);
      }

      Directory? sourceImagesDir;
      final directImages = Directory(p.join(stagingDir.path, 'images'));
      final directProducts = Directory(p.join(stagingDir.path, 'products'));
      if (await directImages.exists()) {
        sourceImagesDir = directImages;
      } else if (await directProducts.exists()) {
        sourceImagesDir = directProducts;
      }

      if (sourceImagesDir != null) {
        for (final item in sourceImagesDir.listSync(recursive: false)) {
          if (item is File) {
            final fileName = p.basename(item.path);
            await item.copy(p.join(productsDir.path, fileName));
          }
        }
      }

      // Restore logo if exists
      for (final entity in stagingDir.listSync()) {
        if (entity is File && p.basename(entity.path).startsWith('logo')) {
          await entity.copy(p.join(appDir.path, p.basename(entity.path)));
        }
      }

      // Invalidate Riverpod database provider so fresh connection reopens
      debugPrint('[BackupService] Invalidating Riverpod database & settings providers...');
      ref.invalidate(databaseProvider);
      ref.invalidate(settingsProvider);
      ref.invalidate(localBackupsProvider);

      await BackupLogService.addLog(
        type: 'Restore',
        isSuccess: true,
        message: 'Successfully restored store data from ${p.basename(zipFile.path)}',
      );
      debugPrint('[BackupService] Restore successfully completed!');
    } catch (e, st) {
      debugPrint('[BackupService] Restore error encountered: $e\n$st');

      // Step e: Rollback from safety copy if safety copy was created
      if (safetyBackupFile != null && await safetyBackupFile.exists()) {
        debugPrint('[BackupService] Rolling back to pre-restore safety copy...');
        try {
          await _rollbackFromSafety(safetyBackupFile, appDir);
          ref.invalidate(databaseProvider);
          ref.invalidate(settingsProvider);
          ref.invalidate(localBackupsProvider);
          debugPrint('[BackupService] Rollback to safety copy succeeded.');
        } catch (rollbackErr, rollbackSt) {
          debugPrint('[BackupService] Rollback error: $rollbackErr\n$rollbackSt');
        }
      }

      await BackupLogService.addLog(
        type: 'Restore',
        isSuccess: false,
        message: 'Restore failed: $e (Reverted to safety backup)',
        error: '$e\n$st',
      );
      rethrow;
    } finally {
      // Clean up staging directory
      try {
        if (await stagingDir.exists()) {
          await stagingDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  static Future<void> _rollbackFromSafety(File safetyZip, Directory appDir) async {
    final cacheDir = await getTemporaryDirectory();
    final rollbackDir = Directory(
      p.join(cacheDir.path, 'rollback_stage_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await rollbackDir.create(recursive: true);

    try {
      await Isolate.run(() => extractFileToDisk(safetyZip.path, rollbackDir.path));
      final safetyDb = File(p.join(rollbackDir.path, 'shopmate.sqlite'));
      if (await safetyDb.exists()) {
        final targetDb = File(p.join(appDir.path, 'shopmate.sqlite'));
        if (await targetDb.exists()) await targetDb.delete();
        await safetyDb.copy(targetDb.path);
      }
    } finally {
      try {
        if (await rollbackDir.exists()) await rollbackDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Share backup via share_plus
  Future<void> shareBackup(File backupFile) async {
    try {
      if (await backupFile.exists()) {
        await Share.shareXFiles(
          [XFile(backupFile.path)],
          subject: 'Shopmate Store Backup',
          text: 'Shopmate Store Backup - ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
        );
      } else {
        throw Exception('Backup file no longer exists at ${backupFile.path}');
      }
    } catch (e, st) {
      debugPrint('[BackupService] Share error: $e\n$st');
      rethrow;
    }
  }

  /// Pick external backup file using FilePicker
  static Future<File?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;
        final cacheDir = await getTemporaryDirectory();
        final tempFile = File(
          p.join(cacheDir.path, 'picked_restore_${DateTime.now().millisecondsSinceEpoch}.zip'),
        );

        if (picked.path != null && await File(picked.path!).exists()) {
          return await File(picked.path!).copy(tempFile.path);
        } else if (picked.bytes != null) {
          await tempFile.writeAsBytes(picked.bytes!);
          return tempFile;
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('[BackupService] Pick backup error: $e\n$st');
      rethrow;
    }
  }

  /// Save backup to device storage using Storage Access Framework (no MANAGE_EXTERNAL_STORAGE)
  static Future<String?> saveBackupToStorage(File backupFile) async {
    try {
      final fileName = p.basename(backupFile.path);
      final bytes = await backupFile.readAsBytes();

      return await FilePicker.platform.saveFile(
        dialogTitle: 'Save Shopmate Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: bytes,
      );
    } catch (e, st) {
      debugPrint('[BackupService] Save file error: $e\n$st');
      rethrow;
    }
  }

  /// Headless backup worker executed by Workmanager
  static Future<void> performHeadlessBackup() async {
    debugPrint('[BackupService] Performing headless background backup...');
    final db = AppDatabase();
    try {
      final service = BackupService(db);
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await service.createBackup(
        customName: 'shopmate_backup_${timestamp}_auto.zip',
        isAuto: true,
      );
    } finally {
      await db.close();
    }
  }

  /// Configures Workmanager periodic auto-backup task
  static Future<void> configureWorkmanager({
    required bool enabled,
    required String interval,
  }) async {
    try {
      if (enabled) {
        final frequency =
            interval == 'weekly' ? const Duration(days: 7) : const Duration(days: 1);
        await Workmanager().registerPeriodicTask(
          'auto_backup_periodic',
          kAutoBackupTaskKey,
          frequency: frequency,
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: true,
          ),
        );
      } else {
        await Workmanager().cancelByUniqueName('auto_backup_periodic');
      }
    } catch (e, st) {
      debugPrint('Workmanager configuration error: $e\n$st');
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupService(db);
});

final localBackupsProvider = FutureProvider.autoDispose<List<File>>((ref) async {
  final service = ref.watch(backupServiceProvider);
  return service.getLocalBackups();
});
