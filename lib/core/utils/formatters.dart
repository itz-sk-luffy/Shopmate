import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(num amount, {String symbol = '₹', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '$symbol ',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatQuantity(double qty, String unit) {
    if (qty == qty.roundToDouble()) {
      return '${qty.toInt()} $unit';
    }
    return '${qty.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')} $unit';
  }

  static String date(DateTime dt, {String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern).format(dt);
  }

  static String time(DateTime dt, {String pattern = 'hh:mm a'}) {
    return DateFormat(pattern).format(dt);
  }

  static String formatTime(DateTime dt, {String pattern = 'hh:mm a'}) => time(dt, pattern: pattern);

  static String formatDate(DateTime dt, {String pattern = 'dd MMM yyyy'}) => date(dt, pattern: pattern);

  static String dateTime(DateTime dt) {
    return '${date(dt)}, ${time(dt)}';
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  // Convert number to Indian words format for A4 PDF invoice (e.g., 1450 -> "One Thousand Four Hundred Fifty Rupees Only")
  static String numberToWordsIndian(double amount) {
    final total = amount.round();
    if (total == 0) return 'Zero Rupees Only';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertLessThanOneThousand(int number) {
      String current;

      if (number % 100 < 20) {
        current = units[number % 100];
        number = (number / 100).floor();
      } else {
        current = units[number % 10];
        number = (number / 10).floor();

        current = '${tens[number % 10]} $current';
        number = (number / 10).floor();
      }
      if (number == 0) return current.trim();
      return '${units[number]} Hundred $current'.trim();
    }

    int remaining = total;
    String result = '';

    // Crores
    final crores = (remaining / 10000000).floor();
    if (crores > 0) {
      result += '${convertLessThanOneThousand(crores)} Crore ';
      remaining %= 10000000;
    }

    // Lakhs
    final lakhs = (remaining / 100000).floor();
    if (lakhs > 0) {
      result += '${convertLessThanOneThousand(lakhs)} Lakh ';
      remaining %= 100000;
    }

    // Thousands
    final thousands = (remaining / 1000).floor();
    if (thousands > 0) {
      result += '${convertLessThanOneThousand(thousands)} Thousand ';
      remaining %= 1000;
    }

    // Hundreds & Tens
    if (remaining > 0) {
      result += convertLessThanOneThousand(remaining);
    }

    return '${result.trim()} Rupees Only';
  }
}
