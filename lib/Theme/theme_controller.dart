import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _keyBool = 'dark_mode';
  static const _keyOld  = 'theme_mode'; // để migrate từ bản cũ (light/dark/system)

  bool _isDark = false; // mặc định Light Mode
  bool get isDark => _isDark;

  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(_keyBool)) {
      _isDark = prefs.getBool(_keyBool) ?? false;
    } else {
      // migrate từ key cũ (nếu có)
      final old = prefs.getString(_keyOld);
      _isDark = (old == 'dark'); // 'system' hoặc null -> false (Light)
      await prefs.setBool(_keyBool, _isDark);
    }
    notifyListeners();
  }

  Future<void> setDarkEnabled(bool enabled) async {
    _isDark = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBool, _isDark);
  }

  Future<void> toggle() => setDarkEnabled(!_isDark);
}
