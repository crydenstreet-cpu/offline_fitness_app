// lib/theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  static const _key = 'themeMode'; // 'system' | 'light' | 'dark'
  final SharedPreferences _prefs;

  ThemeController._(ThemeMode mode, this._prefs) : super(mode);

  static Future<ThemeController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? 'system';
    return ThemeController._(_parse(raw), prefs);
  }

  void setMode(ThemeMode mode) {
    if (mode == value) return;
    value = mode;
    _prefs.setString(_key, _encode(mode));
    notifyListeners();
  }

  static ThemeMode _parse(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark:  return 'dark';
      case ThemeMode.system:
      default:              return 'system';
    }
  }
}
