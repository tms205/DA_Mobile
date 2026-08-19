import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyCatalogItem {
  const CurrencyCatalogItem({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

class CurrencyRatesSnapshot {
  const CurrencyRatesSnapshot({
    required this.base,
    required this.date,
    required this.rates,
  });

  final String base;
  final DateTime? date;
  final Map<String, double> rates;
}

class CurrencyService {
  CurrencyService({http.Client? client}) : _client = client ?? http.Client();

  static const _apiBase = 'https://api.frankfurter.dev/v2';//api lấy tỉ giá tiền tệ
  final http.Client _client;

  Future<List<CurrencyCatalogItem>> fetchCurrencies() async {
    final uri = Uri.parse('$_apiBase/currencies');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách tiền tệ');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded.entries
        .map((entry) => CurrencyCatalogItem(
              code: entry.key.toUpperCase(),
              name: entry.value.toString(),
            ))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  Future<CurrencyRatesSnapshot> fetchRates({String base = 'VND'}) async {
    final uri = Uri.parse('$_apiBase/rates?base=$base');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Không thể tải tỷ giá');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = <String, double>{base.toUpperCase(): 1};
    final rawRates = decoded['rates'] as Map<String, dynamic>? ?? {};
    for (final entry in rawRates.entries) {
      final value = entry.value;
      if (value is num) rates[entry.key.toUpperCase()] = value.toDouble();
    }

    return CurrencyRatesSnapshot(
      base: (decoded['base'] as String? ?? base).toUpperCase(),
      date: DateTime.tryParse(decoded['date'] as String? ?? ''),
      rates: rates,
    );
  }
}
