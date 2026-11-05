import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/backup_log_service.dart';

class BackupLogScreen extends StatefulWidget {
  const BackupLogScreen({super.key});

  @override
  State<BackupLogScreen> createState() => _BackupLogScreenState();
}

class _BackupLogScreenState extends State<BackupLogScreen> {
  late Future<List<BackupLogEntry>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = BackupLogService.getLogs();
    });
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Backup Logs?'),
        content: const Text('This will delete all previous backup and restore history logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BackupLogService.clearLogs();
      _refreshLogs();
    }
  }

  void _showErrorDetails(BackupLogEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed),
            const SizedBox(width: 8),
            Text(entry.type, style: AppTypography.heading3),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Time: ${DateFormat('dd MMM yyyy, hh:mm:ss a').format(entry.timestamp)}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 8),
              Text(entry.message, style: AppTypography.bodyMedium),
              if (entry.error != null && entry.error!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Stack Trace & Details:', style: AppTypography.captionBold),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    entry.error!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: FutureBuilder<List<BackupLogEntry>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(height: 12),
                    const Text('No Backup Logs Yet', style: AppTypography.section),
                    const SizedBox(height: 6),
                    const Text(
                      'All manual exports, scheduled auto-backups, and restore events will be recorded here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: log.isSuccess
                        ? AppColors.successGreen.withValues(alpha: 0.12)
                        : AppColors.errorRed.withValues(alpha: 0.12),
                    child: Icon(
                      log.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: log.isSuccess ? AppColors.successGreen : AppColors.errorRed,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        log.type,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.isSuccess
                              ? AppColors.successGreen.withValues(alpha: 0.1)
                              : AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.isSuccess ? 'SUCCESS' : 'FAILED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: log.isSuccess ? AppColors.successGreen : AppColors.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        log.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: !log.isSuccess
                      ? IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: AppColors.errorRed),
                          tooltip: 'View Error',
                          onPressed: () => _showErrorDetails(log),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

