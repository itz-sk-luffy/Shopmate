import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/billing_repository.dart';
import '../providers/cart_provider.dart';
import 'customer_select_dialog.dart';
import 'sale_complete_dialog.dart';
import '../../../../core/routing/app_router.dart';
import '../../../backup/services/backup_log_service.dart';
import '../../../dashboard/data/dashboard_repository.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  final String currencySymbol;
  final Function(Bill bill)? onSaleComplete;

  const CheckoutSheet({
    super.key,
    required this.currencySymbol,
    this.onSaleComplete,
  });

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  final TextEditingController _cashTenderedController = TextEditingController();
  final TextEditingController _splitCashController = TextEditingController();
  final TextEditingController _splitDigitalController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    // Default cash tendered to grand total
    _cashTenderedController.text = cart.grandTotal.toStringAsFixed(0);
    ref.read(cartProvider.notifier).setCashTendered(cart.grandTotal);
  }

  @override
  void dispose() {
    _cashTenderedController.dispose();
    _splitCashController.dispose();
    _splitDigitalController.dispose();
    super.dispose();
  }

  void _onCashKeypadPress(String char) {
    HapticFeedback.selectionClick();
    final text = _cashTenderedController.text;
    if (char == '⌫') {
      if (text.isNotEmpty) {
        final newText = text.substring(0, text.length - 1);
        _cashTenderedController.text = newText;
        ref.read(cartProvider.notifier).setCashTendered(double.tryParse(newText) ?? 0.0);
      }
    } else if (char == '.') {
      if (!text.contains('.')) {
        final newText = text.isEmpty ? '0.' : '$text.';
        _cashTenderedController.text = newText;
        ref.read(cartProvider.notifier).setCashTendered(double.tryParse(newText) ?? 0.0);
      }
    } else {
      final newText = (text == '0') ? char : text + char;
      _cashTenderedController.text = newText;
      ref.read(cartProvider.notifier).setCashTendered(double.tryParse(newText) ?? 0.0);
    }
  }

  void _setExactCash(double amount) {
    HapticFeedback.lightImpact();
    _cashTenderedController.text = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    ref.read(cartProvider.notifier).setCashTendered(amount);
  }

  void _showDiscountDialog() {
    final cart = ref.read(cartProvider);
    bool isPct = cart.isBillDiscountPercent;
    final ctrl = TextEditingController(
      text: isPct
          ? cart.billDiscountPercent.toStringAsFixed(0)
          : cart.billDiscountAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Bill Discount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Flat (₹)'),
                    selected: !isPct,
                    onSelected: (val) {
                      if (val) setDlgState(() => isPct = false);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Percent (%)'),
                    selected: isPct,
                    onSelected: (val) {
                      if (val) setDlgState(() => isPct = true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isPct ? 'Discount %' : 'Discount Amount',
                  prefixText: isPct ? '' : '₹ ',
                  suffixText: isPct ? '%' : '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearBillDiscount();
                Navigator.pop(ctx);
              },
              child: const Text('Remove Discount'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
                if (isPct) {
                  ref.read(cartProvider.notifier).setBillDiscountPercent(val);
                } else {
                  ref.read(cartProvider.notifier).setBillDiscountAmount(val);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _completeSale() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    // Credit validation
    if (cart.paymentMode == 'Credit' && cart.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a customer for Credit (Udhaar) sales!'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      _showCustomerPicker();
      return;
    }

    // Split validation
    if (cart.paymentMode == 'Split') {
      final cashVal = double.tryParse(_splitCashController.text.trim()) ?? 0.0;
      final digVal = double.tryParse(_splitDigitalController.text.trim()) ?? 0.0;
      if (cashVal + digVal < cart.grandTotal - 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split total must equal or exceed bill amount!'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }
      ref.read(cartProvider.notifier).setCashTendered(cashVal);
      ref.read(cartProvider.notifier).setDigitalAmount(digVal);
    }

    setState(() => _isProcessing = true);
    try {
      final billingRepo = ref.read(billingRepositoryProvider);
      final createdBill = await billingRepo.createBill(cart);

      HapticFeedback.heavyImpact();

      if (mounted) {
        final billId = createdBill.id;
        setState(() => _isProcessing = false);
        Navigator.pop(context); // Close checkout sheet

        // Trigger callback or show SaleCompleteDialog
        if (widget.onSaleComplete != null) {
          widget.onSaleComplete!(createdBill);
        } else {
          final rootCtx = rootNavigatorKey.currentContext;
          if (rootCtx != null && rootCtx.mounted) {
            showDialog(
              context: rootCtx,
              useRootNavigator: true,
              barrierDismissible: false,
              builder: (ctx) => SaleCompleteDialog(billId: billId),
            );
          }
        }

        // Clear cart
        ref.read(cartProvider.notifier).clearCart();

        // Invalidate dashboard metrics & hourly sales trend so real-time updates reflect immediately
        ref.invalidate(dashboardMetricsFamilyProvider);
        ref.invalidate(hourlySalesProvider);
        ref.invalidate(topProductsProvider);
        ref.invalidate(paymentBreakdownProvider);
      }
    } catch (e, stackTrace) {
      await BackupLogService.addLog(
        type: 'Billing Error',
        isSuccess: false,
        message: "Couldn't save the bill",
        error: '$e\n$stackTrace',
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = "Couldn't save the bill, please try again";
        });
      }
    }
  }

  void _showCustomerPicker() {
    final cart = ref.read(cartProvider);
    showDialog(
      context: context,
      builder: (ctx) => CustomerSelectDialog(
        currentCustomer: cart.selectedCustomer,
        currencySymbol: widget.currencySymbol,
        onSelected: (customer) {
          ref.read(cartProvider.notifier).setCustomer(customer);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);

    // Calculate quick cash suggestions
    final grandTotal = cart.grandTotal;
    final next50 = (grandTotal / 50).ceil() * 50.0;
    final next100 = (grandTotal / 100).ceil() * 100.0;
    final next500 = (grandTotal / 500).ceil() * 500.0;
    final cashSuggestions = <double>{
      grandTotal,
      if (next50 > grandTotal) next50,
      if (next100 > grandTotal && next100 != next50) next100,
      if (next500 > grandTotal && next500 != next100) next500,
    }.toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Checkout & Payment', style: AppTypography.heading3.copyWith(fontSize: 18)),
                      Text(
                        '${cart.itemCount} items • ${cart.totalUnits.toStringAsFixed(1)} units',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.errorRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.errorRed),
                          onPressed: () => setState(() => _errorMessage = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Customer Attached Card
                InkWell(
                  onTap: _showCustomerPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cart.selectedCustomer != null
                            ? theme.colorScheme.primary
                            : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: cart.selectedCustomer != null ? theme.colorScheme.primary : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cart.selectedCustomer?.name ?? 'Walk-in Customer (Tap to attach)',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (cart.selectedCustomer?.phone != null)
                                Text(cart.selectedCustomer!.phone!, style: AppTypography.caption),
                            ],
                          ),
                        ),
                        if (cart.selectedCustomer != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.currency(cart.selectedCustomer!.balance, symbol: widget.currencySymbol),
                                style: AppTypography.priceBold.copyWith(
                                  fontSize: 14,
                                  color: cart.selectedCustomer!.balance > 0 ? AppColors.errorRed : Colors.grey,
                                ),
                              ),
                              if (cart.selectedCustomer!.balance > 0)
                                Text('Udhaar', style: AppTypography.caption.copyWith(color: AppColors.errorRed, fontSize: 10)),
                            ],
                          )
                        else
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Mode Selector Tabs
                const Text('Payment Mode', style: AppTypography.captionBold),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Cash', 'UPI', 'Card', 'Credit', 'Split'].map((mode) {
                      final isSelected = cart.paymentMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            mode == 'Cash'
                                ? Icons.payments_rounded
                                : (mode == 'UPI'
                                    ? Icons.account_balance_rounded
                                    : (mode == 'Card'
                                        ? Icons.credit_card_rounded
                                        : (mode == 'Credit' ? Icons.history_edu_rounded : Icons.call_split_rounded))),
                            size: 16,
                            color: isSelected ? Colors.white : theme.colorScheme.primary,
                          ),
                          label: Text(mode == 'Credit' ? 'Credit (Udhaar)' : mode),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              ref.read(cartProvider.notifier).setPaymentMode(mode);
                              if (mode == 'Split') {
                                _splitCashController.text = (cart.grandTotal / 2).toStringAsFixed(0);
                                _splitDigitalController.text = (cart.grandTotal / 2).toStringAsFixed(0);
                              }
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Mode Specific UI
                if (cart.paymentMode == 'Cash') ...[
                  // Cash Tendered & Change Due Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cash Tendered', style: AppTypography.captionBold),
                            Text(
                              '${widget.currencySymbol} ${_cashTenderedController.text.isEmpty ? '0' : _cashTenderedController.text}',
                              style: AppTypography.priceBold.copyWith(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Quick suggestion chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: cashSuggestions.map((amt) {
                            final isSelected = (cart.cashTendered - amt).abs() < 0.01;
                            return ActionChip(
                              label: Text(
                                amt == grandTotal
                                    ? 'Exact (${Formatters.currency(amt, symbol: widget.currencySymbol)})'
                                    : Formatters.currency(amt, symbol: widget.currencySymbol),
                              ),
                              backgroundColor: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
                              side: isSelected ? BorderSide(color: theme.colorScheme.primary) : null,
                              onPressed: () => _setExactCash(amt),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Change Due Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: cart.changeDue > 0
                                ? AppColors.successGreen.withValues(alpha: 0.12)
                                : (cart.cashTendered >= cart.grandTotal
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : AppColors.errorRed.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cart.cashTendered >= cart.grandTotal ? 'Change to Return:' : 'Remaining Due:',
                                style: AppTypography.captionBold.copyWith(
                                  color: cart.cashTendered >= cart.grandTotal
                                      ? AppColors.successGreen
                                      : AppColors.errorRed,
                                ),
                              ),
                              Text(
                                Formatters.currency(
                                  cart.cashTendered >= cart.grandTotal ? cart.changeDue : (cart.grandTotal - cart.cashTendered),
                                  symbol: widget.currencySymbol,
                                ),
                                style: AppTypography.priceBold.copyWith(
                                  fontSize: 18,
                                  color: cart.cashTendered >= cart.grandTotal
                                      ? AppColors.successGreen
                                      : AppColors.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Keypad for Cash Tendered
                        _buildCashKeypad(isDark),
                      ],
                    ),
                  ),
                ] else if (cart.paymentMode == 'UPI') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UPI Payment Accepted', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Collect ${Formatters.currency(cart.grandTotal, symbol: widget.currencySymbol)} via your UPI Soundbox / QR code', style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (cart.paymentMode == 'Card') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Card Payment Accepted', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Swipe / Dip card on POS EDC machine for ${Formatters.currency(cart.grandTotal, symbol: widget.currencySymbol)}', style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (cart.paymentMode == 'Credit') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_edu_rounded, color: Color(0xFFB45309), size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cart.selectedCustomer != null
                                    ? 'Udhaar Credit to: ${cart.selectedCustomer!.name}'
                                    : 'Please attach customer account for Credit',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (cart.selectedCustomer != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Current Udhaar: ${Formatters.currency(cart.selectedCustomer!.balance, symbol: widget.currencySymbol)} → New Total: ${Formatters.currency(cart.selectedCustomer!.balance + cart.grandTotal, symbol: widget.currencySymbol)}',
                            style: AppTypography.captionBold.copyWith(color: const Color(0xFFB45309)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (cart.paymentMode == 'Split') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _splitCashController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Cash Amount',
                                  prefixText: '₹ ',
                                ),
                                onChanged: (val) {
                                  final cash = double.tryParse(val) ?? 0.0;
                                  final dig = max(0.0, cart.grandTotal - cash);
                                  _splitDigitalController.text = dig.toStringAsFixed(0);
                                  ref.read(cartProvider.notifier).setCashTendered(cash);
                                  ref.read(cartProvider.notifier).setDigitalAmount(dig);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _splitDigitalController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Digital Amount',
                                  prefixText: '₹ ',
                                ),
                                onChanged: (val) {
                                  final dig = double.tryParse(val) ?? 0.0;
                                  ref.read(cartProvider.notifier).setDigitalAmount(dig);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Bill Financial Breakdown Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', Formatters.currency(cart.rawSubtotal, symbol: widget.currencySymbol)),
                      if (cart.itemsDiscountTotal > 0)
                        _buildSummaryRow(
                          'Item Discounts',
                          '- ${Formatters.currency(cart.itemsDiscountTotal, symbol: widget.currencySymbol)}',
                          color: AppColors.successGreen,
                        ),
                      // Bill Discount Row with Tap to Edit
                      InkWell(
                        onTap: _showDiscountDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cart.billDiscountTotal > 0
                                        ? 'Bill Discount (${cart.isBillDiscountPercent ? '${cart.billDiscountPercent.toStringAsFixed(0)}%' : 'Flat'})'
                                        : 'Add Bill Discount',
                                    style: AppTypography.caption.copyWith(color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_outlined, size: 14, color: theme.colorScheme.primary),
                                ],
                              ),
                              Text(
                                cart.billDiscountTotal > 0
                                    ? '- ${Formatters.currency(cart.billDiscountTotal, symbol: widget.currencySymbol)}'
                                    : '₹ 0.00',
                                style: AppTypography.priceRegular.copyWith(
                                  color: cart.billDiscountTotal > 0 ? AppColors.successGreen : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (cart.gstType != 'none' && cart.totalGst > 0) ...[
                        _buildSummaryRow('Taxable value', Formatters.currency(cart.taxableAmount, symbol: widget.currencySymbol)),
                        if (cart.isInterState)
                          for (final b in cart.rateBreakups)
                            _buildSummaryRow('IGST ${b.igstRate.toStringAsFixed(b.igstRate.truncateToDouble() == b.igstRate ? 0 : 1)}%',
                                Formatters.currency(b.igstAmount, symbol: widget.currencySymbol))
                        else
                          for (final b in cart.rateBreakups) ...[
                            _buildSummaryRow('CGST ${b.cgstRate.toStringAsFixed(b.cgstRate.truncateToDouble() == b.cgstRate ? 0 : 1)}%',
                                Formatters.currency(b.cgstAmount, symbol: widget.currencySymbol)),
                            _buildSummaryRow('SGST ${b.sgstRate.toStringAsFixed(b.sgstRate.truncateToDouble() == b.sgstRate ? 0 : 1)}%',
                                Formatters.currency(b.sgstAmount, symbol: widget.currencySymbol)),
                          ],
                      ],
                      if (cart.roundOff.abs() > 0.001)
                        _buildSummaryRow(
                          'Round-off',
                          '${cart.roundOff >= 0 ? '+' : ''}${cart.roundOff.toStringAsFixed(2)}',
                        ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total', style: AppTypography.heading3.copyWith(fontSize: 18)),
                          Text(
                            Formatters.currency(cart.grandTotal, symbol: widget.currencySymbol),
                            style: AppTypography.priceBold.copyWith(
                              fontSize: 22,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Charge Button Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : AppColors.lightOutline)),
            ),
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : _completeSale,
              icon: _isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isProcessing
                    ? 'Processing Sale...'
                    : 'Complete Sale • ${Formatters.currency(cart.grandTotal, symbol: widget.currencySymbol)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(
            value,
            style: AppTypography.priceRegular.copyWith(
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashKeypad(bool isDark) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: row.map((char) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _onCashKeypadPress(char),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: char == '⌫'
                          ? const Icon(Icons.backspace_outlined, size: 18)
                          : Text(
                              char,
                              style: AppTypography.priceMedium.copyWith(fontSize: 18),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
