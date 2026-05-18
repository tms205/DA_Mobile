import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/formatters.dart';
import '../data/services/currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider({CurrencyService? service}) : _service = service ?? CurrencyService();

  static const _selectedCurrencyKey = 'settings_currency_code';
  static const _ratesUpdatedAtKey = 'settings_currency_rates_updated_at';

  final CurrencyService _service;

  String _selectedCurrency = CurrencyFormatter.baseCurrencyCode;
  Map<String, String> _currencies = const {
    'VND': 'Vietnamese Dong',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'JPY': 'Japanese Yen',
    'GBP': 'British Pound',
    'CNY': 'Chinese Yuan',
    'KRW': 'South Korean Won',
    'THB': 'Thai Baht',
    'SGD': 'Singapore Dollar',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
  };
  Map<String, double> _ratesFromVnd = const {
    'VND': 1,
    'USD': 0.000039,
    'EUR': 0.000036,
    'JPY': 0.0061,
    'GBP': 0.000031,
    'CNY': 0.00028,
    'KRW': 0.054,
    'THB': 0.0014,
    'SGD': 0.000052,
    'AUD': 0.000060,
    'CAD': 0.000054,
  };

  DateTime? _ratesUpdatedAt;
  bool _isLoading = false;
  String? _errorMessage;

  String get selectedCurrency => _selectedCurrency;
  Map<String, String> get currencies => _currencies;
  Map<String, double> get ratesFromVnd => _ratesFromVnd;
  DateTime? get ratesUpdatedAt => _ratesUpdatedAt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedCurrencyName => _currencies[_selectedCurrency] ?? _selectedCurrency;
  double get selectedRate => _ratesFromVnd[_selectedCurrency] ?? 1;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString(_selectedCurrencyKey) ?? CurrencyFormatter.baseCurrencyCode;
    _ratesUpdatedAt = DateTime.tryParse(prefs.getString(_ratesUpdatedAtKey) ?? '');
    _applyFormatter();
    await refreshRates(silent: true);
  }

  Future<void> changeCurrency(String code) async {
    _selectedCurrency = code.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCurrencyKey, _selectedCurrency);
    _applyFormatter();
    notifyListeners();
  }

  Future<void> refreshRates({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _service.fetchCurrencies(),
        _service.fetchRates(base: CurrencyFormatter.baseCurrencyCode),
      ]);
      final catalog = results[0] as List<CurrencyCatalogItem>;
      final snapshot = results[1] as CurrencyRatesSnapshot;

      _currencies = {
        for (final item in catalog) item.code: item.name,
        CurrencyFormatter.baseCurrencyCode: 'Vietnamese Dong',
      };
      _ratesFromVnd = {
        ...snapshot.rates,
        CurrencyFormatter.baseCurrencyCode: 1,
      };
      _ratesUpdatedAt = snapshot.date ?? DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ratesUpdatedAtKey, _ratesUpdatedAt!.toIso8601String());
      _applyFormatter();
    } catch (_) {
      _errorMessage = 'Không tải được tỷ giá mới, đang dùng tỷ giá dự phòng.';
      _applyFormatter();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFormatter() {
    CurrencyFormatter.configure(
      code: _selectedCurrency,
      symbol: CurrencySymbols.symbolFor(_selectedCurrency),
      rateFromVnd: _ratesFromVnd[_selectedCurrency] ?? 1,
    );
  }
}
