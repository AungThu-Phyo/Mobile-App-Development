import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentProvider extends ChangeNotifier {
  static const String _consentKey = 'privacy_consent_accepted';

  bool _hasConsented = false;
  bool _isLoaded = false;

  bool get hasConsented => _hasConsented;
  bool get isLoaded => _isLoaded;

  Future<void> loadConsent() async {
    final preferences = await SharedPreferences.getInstance();
    _hasConsented = preferences.getBool(_consentKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> acceptConsent() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey, true);
    _hasConsented = true;
    notifyListeners();
  }

  Future<void> resetConsent() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_consentKey);
    _hasConsented = false;
    notifyListeners();
  }
}