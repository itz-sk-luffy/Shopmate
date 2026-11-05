import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../services/thermal_printer_service.dart';

class PrinterScreen extends ConsumerStatefulWidget {
  const PrinterScreen({super.key});

  @override
  ConsumerState<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends ConsumerState<PrinterScreen> {
  bool _isConnecting = false;
  String? _connectedMac;
  String? _connectedName;
  bool _isPrintingTest = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    final service = ref.read(thermalPrinterServiceProvider);
    final isConn = await service.isConnected();
    if (isConn) {
      final db = ref.read(databaseProvider);
      final lastMac = await db.getSetting('last_printer_mac');
      if (mounted) {
        setState(() {
          _connectedMac = lastMac.isNotEmpty ? lastMac : 'Connected';
        });
      }
    }
  }

  void _connectToDevice(BluetoothInfo device) async {
    setState(() => _isConnecting = true);
    final service = ref.read(thermalPrinterServiceProvider);
    final success = await service.connect(device.macAdress);

    if (mounted) {
      setState(() {
        _isConnecting = false;
        if (success) {
          _connectedMac = device.macAdress;
          _connectedName = device.name;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connected to ${device.name}' : 'Could not connect to ${device.name}'),
          backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
        ),
      );
    }
  }

  void _disconnect() async {
    final service = ref.read(thermalPrinterServiceProvider);
    await service.disconnect();
    if (mounted) {
      setState(() {
        _connectedMac = null;
        _connectedName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from printer')),
      );
    }
  }

  void _testPrint() async {
    setState(() => _isPrintingTest = true);
    final service = ref.read(thermalPrinterServiceProvider);
    final success = await service.printTestReceipt();

    if (mounted) {
      setState(() => _isPrintingTest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Test receipt printed successfully!' : 'Printing failed. Check printer connection & paper.'),
          backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final btEnabledAsync = ref.watch(bluetoothEnabledProvider);
    final devicesAsync = ref.watch(bluetoothDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer (58 mm)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Devices',
            onPressed: () {
              ref.invalidate(bluetoothDevicesProvider);
              ref.invalidate(bluetoothEnabledProvider);
              _checkStatus();
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
          // Connection Status Card
          Card(
            color: _connectedMac != null
                ? AppColors.successGreen.withValues(alpha: 0.12)
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _connectedMac != null
                        ? AppColors.successGreen
                        : (isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0)),
                    child: Icon(
                      Icons.print_rounded,
                      color: _connectedMac != null ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connectedMac != null ? 'Printer Connected' : 'No Printer Connected',
                          style: AppTypography.heading3.copyWith(
                            fontSize: 16,
                            color: _connectedMac != null ? AppColors.successGreen : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _connectedMac != null
                              ? (_connectedName != null ? '$_connectedName • $_connectedMac' : _connectedMac!)
                              : 'Select a 58 mm Bluetooth thermal printer below',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  if (_connectedMac != null)
                    OutlinedButton(
                      onPressed: _disconnect,
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Test Print Button (Enabled when connected)
          FilledButton.icon(
            onPressed: _connectedMac != null && !_isPrintingTest ? _testPrint : null,
            icon: _isPrintingTest
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.receipt_long_rounded),
            label: Text(_isPrintingTest ? 'Printing...' : 'Print Test Receipt (58 mm)'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 20),

          // Bluetooth Status Header
          btEnabledAsync.when(
            data: (isEnabled) {
              if (!isEnabled) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bluetooth_disabled_rounded, color: AppColors.errorRed),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bluetooth is turned off. Please turn on Bluetooth in Android Settings to discover printers.',
                          style: TextStyle(color: AppColors.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Paired Devices Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paired Bluetooth Devices', style: AppTypography.captionBold),
              TextButton.icon(
                onPressed: () {
                  ref.invalidate(bluetoothDevicesProvider);
                },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Scan'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Devices List
          devicesAsync.when(
            data: (devices) {
              if (devices.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.bluetooth_searching_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No paired Bluetooth printers found', style: AppTypography.captionBold),
                        SizedBox(height: 4),
                        Text(
                          'Please pair your 58 mm printer in Android Bluetooth Settings first, then tap Scan.',
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final dev = devices[index];
                  final isCurrent = _connectedMac == dev.macAdress;

                  return Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isCurrent
                                ? AppColors.successGreen.withValues(alpha: 0.15)
                                : theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.print_outlined,
                              size: 20,
                              color: isCurrent ? AppColors.successGreen : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dev.name.isEmpty ? 'Unknown Device' : dev.name,
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dev.macAdress,
                                  style: AppTypography.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Connected',
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _isConnecting ? null : () => _connectToDevice(dev),
                              child: const Text('Connect'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          const SizedBox(height: 24),

          // 58 mm Receipt Preferences
          const Text('58 mm Receipt Configuration', style: AppTypography.captionBold),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Print GST Tax Breakdown', style: AppTypography.bodyMedium),
                  subtitle: const Text('Prints CGST & SGST lines on the 58 mm receipt', style: AppTypography.caption),
                  value: settings.receiptShowGst,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateSetting('receipt_show_gst', val ? 'true' : 'false');
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Print Customer Info', style: AppTypography.bodyMedium),
                  subtitle: const Text('Prints customer name and mobile on receipt', style: AppTypography.caption),
                  value: settings.receiptShowCustomer,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateSetting('receipt_show_customer', val ? 'true' : 'false');
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Print Store Footer Note', style: AppTypography.bodyMedium),
                  subtitle: const Text('Prints thank-you note and visit again message', style: AppTypography.caption),
                  value: settings.receiptShowFooter,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateSetting('receipt_show_footer', val ? 'true' : 'false');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Paper Feed Lines Before Cut', style: AppTypography.bodyMedium),
                  subtitle: Text('${settings.printCutFeed} feed lines', style: AppTypography.caption),
                  trailing: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decrease feed lines',
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: settings.printCutFeed > 0
                              ? () {
                                  ref.read(settingsProvider.notifier).updateSetting('print_cut_feed', '${settings.printCutFeed - 1}');
                                }
                              : null,
                        ),
                        Semantics(
                          label: '${settings.printCutFeed} feed lines',
                          child: SizedBox(
                            width: 28,
                            child: Text(
                              '${settings.printCutFeed}',
                              style: AppTypography.priceBold,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Increase feed lines',
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          onPressed: settings.printCutFeed < 10
                              ? () {
                                  ref.read(settingsProvider.notifier).updateSetting('print_cut_feed', '${settings.printCutFeed + 1}');
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
