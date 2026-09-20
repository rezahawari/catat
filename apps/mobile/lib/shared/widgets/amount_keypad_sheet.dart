import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';

class AmountKeypadSheet extends StatefulWidget {
  final double initialAmount;
  final ValueChanged<double> onAmountConfirmed;

  const AmountKeypadSheet({
    super.key,
    this.initialAmount = 0,
    required this.onAmountConfirmed,
  });

  @override
  State<AmountKeypadSheet> createState() => _AmountKeypadSheetState();
}

class _AmountKeypadSheetState extends State<AmountKeypadSheet> {
  String _inputBuffer = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      _inputBuffer = widget.initialAmount.toInt().toString();
    }
  }

  double get _currentAmount => double.tryParse(_inputBuffer) ?? 0;

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _inputBuffer = '';
      } else if (key == '⌫') {
        if (_inputBuffer.isNotEmpty) {
          _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
        }
      } else if (key == '000') {
        if (_inputBuffer.isNotEmpty && _inputBuffer.length < 11) {
          _inputBuffer += '000';
        }
      } else {
        if (_inputBuffer.length < 12) {
          _inputBuffer += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['000', '0', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Nominal Transaksi',
            style: AppTypography.labelLarge(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Display Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(_currentAmount),
              style: AppTypography.displayLarge(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Numeric Pad
          ...keys.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((key) {
                    final isAction = key == '⌫' || key == 'C';
                    return InkWell(
                      onTap: () => _onKeyPress(key),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isAction
                              ? (isDark ? AppColors.darkCard : AppColors.lightBackground)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          key,
                          style: AppTypography.headlineMedium(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )),

          const SizedBox(height: 12),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _currentAmount > 0
                  ? () {
                      widget.onAmountConfirmed(_currentAmount);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Lanjutkan'),
            ),
          ),
        ],
      ),
    );
  }
}
