import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('theme_mode') ?? 'system';
    mode.value = _fromString(raw);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    mode.value = m;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('theme_mode', _toString(m));
  }

  String _toString(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system';

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'dark': return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default: return ThemeMode.system;
    }
  }
}
