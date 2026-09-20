import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final _compactFormat = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );

  static String format(double amount, {bool showSymbol = true}) {
    final result = _currencyFormat.format(amount);
    if (!showSymbol) {
      return result.replaceAll('Rp', '').trim();
    }
    return result;
  }

  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }
}
