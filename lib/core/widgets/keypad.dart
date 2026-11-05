import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final VoidCallback? onSubmit;
  final bool showDecimal;
  final String submitLabel;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    this.onClear,
    this.onSubmit,
    this.showDecimal = true,
    this.submitLabel = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildKey('1', isDark),
              const SizedBox(width: 8),
              _buildKey('2', isDark),
              const SizedBox(width: 8),
              _buildKey('3', isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('4', isDark),
              const SizedBox(width: 8),
              _buildKey('5', isDark),
              const SizedBox(width: 8),
              _buildKey('6', isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('7', isDark),
              const SizedBox(width: 8),
              _buildKey('8', isDark),
              const SizedBox(width: 8),
              _buildKey('9', isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              showDecimal
                  ? _buildKey('.', isDark)
                  : (onClear != null
                      ? _buildActionKey(
                          label: 'C',
                          color: AppColors.errorRed.withValues(alpha: isDark ? 0.2 : 0.1),
                          textColor: AppColors.errorRed,
                          onTap: onClear!,
                        )
                      : const Expanded(child: SizedBox())),
              const SizedBox(width: 8),
              _buildKey('0', isDark),
              const SizedBox(width: 8),
              _buildBackspaceKey(isDark),
            ],
          ),
          if (onSubmit != null) ...[
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onSubmit!();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(submitLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKey(String val, bool isDark) {
    return Expanded(
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onDigitPressed(val);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              val,
              style: AppTypography.priceMedium.copyWith(
                fontSize: 22,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(bool isDark) {
    return Expanded(
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onBackspace();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace_outlined,
              size: 20,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.priceMedium.copyWith(
                fontSize: 20,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
