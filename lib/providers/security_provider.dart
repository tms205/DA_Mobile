import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  static const _pinHashKey = 'security_pin_hash';
  static const _pinSalt = 'ltdd_nhom9_finance_pin';

  bool _isPinEnabled = false;
  bool _isUnlocked = true;

  bool get isPinEnabled => _isPinEnabled;
  bool get isUnlocked => _isUnlocked;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPinEnabled = prefs.getString(_pinHashKey) != null;
    _isUnlocked = !_isPinEnabled;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hash(pin));
    _isPinEnabled = true;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
    _isPinEnabled = false;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(_pinHashKey);
    final isValid = savedHash != null && savedHash == _hash(pin);
    if (isValid) {
      _isUnlocked = true;
      notifyListeners();
    }
    return isValid;
  }

  void lock() {
    if (!_isPinEnabled) return;
    _isUnlocked = false;
    notifyListeners();
  }

  String _hash(String pin) {
    return sha256.convert(utf8.encode('$_pinSalt:$pin')).toString();
  }
}
