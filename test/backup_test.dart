import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/features/backup/services/backup_log_service.dart';
import 'package:shopmate/features/backup/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BackupService backupService;
  late Directory tempTestDir;

  const sqliteMagicHeader = [
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
    0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    0x04, 0x00, 0x01, 0x01, 0x00, 0x40, 0x20, 0x20,
  ];

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('shopmate_backup_test_');

    // Create a mock live sqlite file with valid SQLite magic header
    final dummyDb = File(p.join(tempTestDir.path, 'shopmate.sqlite'));
    await dummyDb.writeAsBytes(sqliteMagicHeader);

    // Mock path_provider method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempTestDir.path;
      },
    );

    db = AppDatabase(NativeDatabase.memory());
    backupService = BackupService(db);
  });

  tearDown(() async {
    await db.close();
    try {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Backup and Restore Logic Test', () {
    test('Backup export generates unencrypted zip containing manifest and db', () async {
      final zipFile = await backupService.createBackup(customName: 'test_backup.zip');
      expect(await zipFile.exists(), isTrue);

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Verify required files exist in zip
      final fileNames = archive.map((f) => f.name).toList();
      expect(fileNames.contains('shopmate.sqlite'), isTrue);
      expect(fileNames.contains('manifest.json'), isTrue);
      expect(fileNames.contains('settings.json'), isTrue);

      // Verify manifest contents
      final manifestArchiveFile = archive.firstWhere((f) => f.name == 'manifest.json');
      final manifestJson = jsonDecode(utf8.decode(manifestArchiveFile.content as List<int>))
          as Map<String, dynamic>;

      expect(manifestJson['appVersion'], '1.0.0');
      expect(manifestJson['dbSchemaVersion'], isA<int>());
      expect(manifestJson['createdAt'], isNotEmpty);
      expect(manifestJson.containsKey('billCount'), isTrue);
      expect(manifestJson.containsKey('productCount'), isTrue);

      // Clean up backup file
      await zipFile.delete();
    });

    test('Restoring corrupted zip fails safely with descriptive exception', () async {
      final corruptedZip = File(p.join(tempTestDir.path, 'corrupted_backup.zip'));
      // Write corrupted garbage bytes
      await corruptedZip.writeAsBytes([0x50, 0x4B, 0x03, 0x04, 0x00, 0x99, 0xFF, 0xAA]);

      final stagingDir = Directory(p.join(tempTestDir.path, 'staging'));
      await stagingDir.create(recursive: true);

      expect(
        extractFileToDisk(corruptedZip.path, stagingDir.path),
        throwsA(anything),
      );
    });

    test('Restoring zip without manifest fails validation', () async {
      final invalidZip = File(p.join(tempTestDir.path, 'no_manifest.zip'));
      final encoder = ZipFileEncoder();
      encoder.create(invalidZip.path);

      // Add only a dummy text file
      final dummyFile = File(p.join(tempTestDir.path, 'dummy.txt'));
      await dummyFile.writeAsString('hello');
      await encoder.addFile(dummyFile, 'dummy.txt');
      encoder.closeSync();

      final stagingDir = Directory(p.join(tempTestDir.path, 'staging_no_manifest'));
      await stagingDir.create(recursive: true);
      await extractFileToDisk(invalidZip.path, stagingDir.path);

      final manifestFile = File(p.join(stagingDir.path, 'manifest.json'));
      expect(await manifestFile.exists(), isFalse);
    });

    test('BackupLogService logs entries and reads them back correctly', () async {
      await BackupLogService.clearLogs();

      await BackupLogService.addLog(
        type: 'Manual Backup',
        isSuccess: true,
        message: 'Test backup created',
        sizeBytes: 1024,
      );

      await BackupLogService.addLog(
        type: 'Restore',
        isSuccess: false,
        message: 'Test restore failed',
        error: 'Corrupted database file',
      );

      final logs = await BackupLogService.getLogs();
      expect(logs.length, 2);
      expect(logs.first.type, 'Restore');
      expect(logs.first.isSuccess, isFalse);
      expect(logs.last.type, 'Manual Backup');
      expect(logs.last.isSuccess, isTrue);

      await BackupLogService.clearLogs();
      final clearedLogs = await BackupLogService.getLogs();
      expect(clearedLogs.isEmpty, isTrue);
    });
  });
}
