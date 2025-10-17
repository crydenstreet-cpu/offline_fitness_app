// lib/theme/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode_index';

  /// Aktueller Modus (rebuildet via ValueListenableBuilder)
  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Beim App-Start laden (im main() aufrufen)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefsKey);
    if (idx != null && idx >= 0 && idx < ThemeMode.values.length) {
      mode.value = ThemeMode.values[idx];
    } else {
      // Optionaler Default: Dark
      // mode.value = ThemeMode.dark;
    }
  }

  /// Setzen & speichern
  Future<void> setThemeMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, m.index);
  }
}
