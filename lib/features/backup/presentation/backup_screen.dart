import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../services/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isCreating = false;
  bool _isRestoring = false;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _showErrorDialog({required String title, required String message, String? details}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.heading3),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 14)),
              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Technical Details:', style: AppTypography.captionBold),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    details,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
        ],
      ),
    );
  }

  void _showBackupSuccessDialog(File file) {
    final stat = file.statSync();
    final fileName = p.basename(file.path);
    final sizeStr = _formatFileSize(stat.size);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
            SizedBox(width: 8),
            Text('Backup Created', style: AppTypography.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your store database, product images, and settings have been safely compressed.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File: $fileName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Size: $sizeStr', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleSaveToStorage(file);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Save to Storage'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleShareBackup(file);
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveToStorage(File file) async {
    try {
      final savedPath = await BackupService.saveBackupToStorage(file);
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved successfully: ${p.basename(savedPath)}'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[BackupScreen] Save error: $e\n$st');
      if (mounted) {
        _showErrorDialog(
          title: 'Save Failed',
          message: 'Could not save the backup to the chosen folder: $e',
          details: '$e\n$st',
        );
      }
    }
  }

  Future<void> _handleShareBackup(File file) async {
    try {
      final service = ref.read(backupServiceProvider);
      await service.shareBackup(file);
    } catch (e, st) {
      debugPrint('[BackupScreen] Share error: $e\n$st');
      if (mounted) {
        _showErrorDialog(
          title: 'Share Failed',
          message: 'Failed to share backup file: $e',
          details: '$e\n$st',
        );
      }
    }
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isCreating = true);
    try {
      final service = ref.read(backupServiceProvider);
      final file = await service.createBackup();

      if (!mounted) return;
      ref.invalidate(localBackupsProvider);
      _showBackupSuccessDialog(file);
    } catch (e, st) {
      debugPrint('[BackupScreen] Create backup error: $e\n$st');
      if (mounted) {
        _showErrorDialog(
          title: 'Backup Failed',
          message: 'Failed to generate backup archive: $e',
          details: '$e\n$st',
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _handleRestoreFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will replace your current store catalog, orders, and settings with data from this backup.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A safety backup of your current data will be created automatically before restoring.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningAmber),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed & Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final service = ref.read(backupServiceProvider);
      await service.restoreBackup(file, ref: ref);

      if (!mounted) return;
      ref.invalidate(localBackupsProvider);
      ref.invalidate(settingsProvider);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
              SizedBox(width: 8),
              Text('Restore Complete', style: AppTypography.heading3),
            ],
          ),
          content: const Text(
            'Store catalog, past orders, and settings have been successfully restored from backup.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('[BackupScreen] Restore failed: $e\n$st');
      if (mounted) {
        _showErrorDialog(
          title: 'Restore Failed',
          message: '$e',
          details: '$st',
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _handlePickExternalBackup() async {
    try {
      final picked = await BackupService.pickBackupFile();
      if (picked != null) {
        await _handleRestoreFile(picked);
      }
    } catch (e, st) {
      debugPrint('[BackupScreen] Pick file error: $e\n$st');
      if (mounted) {
        _showErrorDialog(
          title: 'Error Selecting File',
          message: 'Could not load selected backup file: $e',
          details: '$e\n$st',
        );
      }
    }
  }

  Future<void> _handleDeleteBackup(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Backup File?'),
        content: const Text('This will permanently delete this backup file from device storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(backupServiceProvider);
        await service.deleteBackup(file);
        ref.invalidate(localBackupsProvider);
      } catch (e, st) {
        if (mounted) {
          _showErrorDialog(
            title: 'Delete Failed',
            message: 'Failed to delete backup file: $e',
            details: '$e\n$st',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final backupsAsync = ref.watch(localBackupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Backup History & Logs',
            onPressed: () => context.push(AppRoutes.backupLog),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Card(
            color: AppColors.primaryTeal.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: AppColors.primaryTeal, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Offline Store Backup',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Plain .zip backup containing SQLite database, product images, and settings. Retains the latest 5 local copies.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card 1: Create Backup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manual Backup', style: AppTypography.heading3),
                  const SizedBox(height: 8),
                  const Text(
                    'Create an instant backup archive of your entire shop catalog, billing history, and settings.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isCreating || _isRestoring ? null : _handleCreateBackup,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.backup_rounded),
                      label: Text(_isCreating ? 'Creating Zip Archive...' : 'Create Backup Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Auto-Backup Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Automated Backup', style: AppTypography.heading3),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.backupLog),
                        icon: const Icon(Icons.list_alt_rounded, size: 16),
                        label: const Text('View Logs', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Auto-Backup',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Background worker runs periodically via Android Workmanager'),
                    value: settings.isAutoBackupEnabled,
                    onChanged: (val) async {
                      await ref
                          .read(settingsProvider.notifier)
                          .updateSetting('auto_backup_enabled', val.toString());
                      await BackupService.configureWorkmanager(
                        enabled: val,
                        interval: settings.autoBackupInterval,
                      );
                    },
                  ),
                  if (settings.isAutoBackupEnabled) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Backup Frequency',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'daily', label: Text('Daily')),
                            ButtonSegment(value: 'weekly', label: Text('Weekly')),
                          ],
                          selected: {settings.autoBackupInterval},
                          onSelectionChanged: (set) async {
                            final val = set.first;
                            await ref
                                .read(settingsProvider.notifier)
                                .updateSetting('auto_backup_interval', val);
                            await BackupService.configureWorkmanager(
                              enabled: settings.isAutoBackupEnabled,
                              interval: val,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card 3: External Restore
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Restore from External .zip', style: AppTypography.heading3),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a previously exported .zip backup from device storage, Google Drive, or SD card.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isCreating || _isRestoring ? null : _handlePickExternalBackup,
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.file_open_rounded),
                      label: Text(_isRestoring
                          ? 'Restoring & Validating...'
                          : 'Select .zip File to Restore'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Card 4: Local Backups List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Local Backups on Device', style: AppTypography.captionBold),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () => ref.invalidate(localBackupsProvider),
              ),
            ],
          ),
          const SizedBox(height: 8),

          backupsAsync.when(
            data: (backups) {
              if (backups.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No local backups found. Tap "Create Backup Now" to make one.'),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: backups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final file = backups[index];
                  final name = p.basename(file.path);
                  final stat = file.statSync();
                  final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(stat.modified);
                  final sizeStr = _formatFileSize(stat.size);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                        child: const Icon(Icons.folder_zip_rounded, color: AppColors.primaryTeal),
                      ),
                      title: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('$dateStr • $sizeStr', style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_rounded, size: 20),
                            tooltip: 'Save to Device Storage',
                            onPressed: () => _handleSaveToStorage(file),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, size: 20),
                            tooltip: 'Share Backup',
                            onPressed: () => _handleShareBackup(file),
                          ),
                          IconButton(
                            icon: const Icon(Icons.restore_rounded,
                                size: 20, color: AppColors.primaryTeal),
                            tooltip: 'Restore from this backup',
                            onPressed: _isRestoring ? null : () => _handleRestoreFile(file),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20, color: AppColors.errorRed),
                            tooltip: 'Delete file',
                            onPressed: () => _handleDeleteBackup(file),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading backups: $err'),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
