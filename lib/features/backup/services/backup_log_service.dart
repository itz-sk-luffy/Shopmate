import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupLogEntry {
  final DateTime timestamp;
  final String type; // 'Manual Backup', 'Auto Backup', 'Restore'
  final bool isSuccess;
  final String message;
  final String? error;
  final int? sizeBytes;

  BackupLogEntry({
    required this.timestamp,
    required this.type,
    required this.isSuccess,
    required this.message,
    this.error,
    this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'isSuccess': isSuccess,
        'message': message,
        'error': error,
        'sizeBytes': sizeBytes,
      };

  factory BackupLogEntry.fromJson(Map<String, dynamic> json) => BackupLogEntry(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        type: json['type'] as String? ?? 'General',
        isSuccess: json['isSuccess'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        error: json['error'] as String?,
        sizeBytes: json['sizeBytes'] as int?,
      );
}

class BackupLogService {
  BackupLogService._();

  static const String _logFileName = 'backup_logs.json';
  static const int _maxLogs = 50;

  static Future<File> _getLogFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(p.join(appDir.path, _logFileName));
  }

  static Future<List<BackupLogEntry>> getLogs() async {
    try {
      final file = await _getLogFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(content) as List<dynamic>;
      final logs = decoded
          .map((item) => BackupLogEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    } catch (e, st) {
      debugPrint('Error reading backup logs: $e\n$st');
      return [];
    }
  }

  static Future<void> addLog({
    required String type,
    required bool isSuccess,
    required String message,
    String? error,
    int? sizeBytes,
  }) async {
    try {
      final logs = await getLogs();
      logs.insert(
        0,
        BackupLogEntry(
          timestamp: DateTime.now(),
          type: type,
          isSuccess: isSuccess,
          message: message,
          error: error,
          sizeBytes: sizeBytes,
        ),
      );

      // Keep only recent logs
      final trimmed = logs.take(_maxLogs).toList();
      final file = await _getLogFile();
      await file.writeAsString(
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      debugPrint('Error writing backup log: $e\n$st');
    }
  }

  static Future<void> clearLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing backup logs: $e');
    }
  }
}

