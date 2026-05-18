import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const String baseCurrencyCode = 'VND';
  static String _currencyCode = baseCurrencyCode;
  static String _currencySymbol = '₫';
  static double _rateFromVnd = 1;

  static final NumberFormat _plain = NumberFormat('#,###', 'vi_VN');

  static void configure({
    required String code,
    required String symbol,
    required double rateFromVnd,
  }) {
    _currencyCode = code;
    _currencySymbol = symbol;
    _rateFromVnd = rateFromVnd <= 0 ? 1 : rateFromVnd;
  }

  static String get currentCode => _currencyCode;
  static String get currentSymbol => _currencySymbol;
  static bool get usesBaseCurrency => _currencyCode == baseCurrencyCode;

  static double fromBase(double amount) => amount * _rateFromVnd;
  static double toBase(double amount) => amount / _rateFromVnd;

  /// Format đầy đủ: 1.500.000 ₫ hoặc 61.35 USD.
  static String format(double amount) {
    final converted = fromBase(amount);
    final formatter = NumberFormat.currency(
      locale: usesBaseCurrency ? 'vi_VN' : 'en_US',
      symbol: usesBaseCurrency ? _currencySymbol : '',
      name: usesBaseCurrency ? null : _currencyCode,
      decimalDigits: usesBaseCurrency ? 0 : 2,
    );
    if (usesBaseCurrency) return formatter.format(converted);
    return '${formatter.format(converted).trim()} $_currencyCode';
  }

  /// Format gọn: 1,5M ₫ hoặc 61.35 USD.
  static String compact(double amount) {
    final converted = fromBase(amount);
    final formatter = NumberFormat.compactCurrency(
      locale: usesBaseCurrency ? 'vi_VN' : 'en_US',
      symbol: usesBaseCurrency ? _currencySymbol : '',
      decimalDigits: usesBaseCurrency ? 1 : 2,
    );
    if (usesBaseCurrency) return formatter.format(converted);
    return '${formatter.format(converted).trim()} $_currencyCode';
  }

  /// Chỉ số dùng cho ô nhập.
  static String plainNumber(double amount) {
    final converted = fromBase(amount);
    if (usesBaseCurrency) return _plain.format(converted);
    return converted.toStringAsFixed(2);
  }

  /// Parse chuỗi thành số
  static double parse(String value) {
    final cleaned = value
        .replaceAll(_currencyCode, '')
        .replaceAll(_currencySymbol, '')
        .replaceAll(' ', '')
        .trim();
    if (!usesBaseCurrency) {
      return double.tryParse(cleaned.replaceAll(',', '')) ?? 0.0;
    }
    final normalized = cleaned.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(normalized) ?? 0.0;
  }

  static double parseToBase(String value) {
    final parsed = parse(value);
    return usesBaseCurrency ? parsed : toBase(parsed);
  }

  static String inputSuffix() {
    return usesBaseCurrency ? _currencySymbol : _currencyCode;
  }
}

class CurrencySymbols {
  CurrencySymbols._();

  static const Map<String, String> values = {
    'VND': '₫',
    'USD': r'$',
    'EUR': '€',
    'JPY': '¥',
    'GBP': '£',
    'CNY': '¥',
    'KRW': '₩',
    'THB': '฿',
    'SGD': r'S$',
    'AUD': r'A$',
    'CAD': r'C$',
    'CHF': 'CHF',
    'HKD': r'HK$',
    'INR': '₹',
    'MYR': 'RM',
    'PHP': '₱',
    'IDR': 'Rp',
  };

  static String symbolFor(String code) {
    return values[code.toUpperCase()] ?? code.toUpperCase();
  }
}

class DateFormatter {
  DateFormatter._();

  static final DateFormat _full = DateFormat('dd/MM/yyyy', 'vi_VN');
  static final DateFormat _monthYear = DateFormat('MM/yyyy', 'vi_VN');
  static final DateFormat _dayMonth = DateFormat('dd/MM', 'vi_VN');
  static final DateFormat _time = DateFormat('HH:mm', 'vi_VN');
  static final DateFormat _fullTime = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');

  static String formatDate(DateTime date) => _full.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);
  static String formatTime(DateTime date) => _time.format(date);
  static String formatDateTime(DateTime date) => _fullTime.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) return '$diff ngày trước';
    return _full.format(date);
  }

  static String monthName(int month) {
    const names = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return names[month - 1];
  }
}
