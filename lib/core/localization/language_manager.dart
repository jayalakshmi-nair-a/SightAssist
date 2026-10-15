import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_keys.dart';
import 'app_localizations.dart';

class LanguageManager extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;
  AppLocalizations get localizations => AppLocalizations(_currentLanguage);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(AppKeys.keyLanguage);
    if (savedCode != null) {
      _currentLanguage = AppLanguage.fromCode(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppKeys.keyLanguage, language.code);
      notifyListeners();
    }
  }

  String getText(String key) => localizations.translate(key);
}
