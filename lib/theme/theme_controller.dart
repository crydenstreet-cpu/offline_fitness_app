import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _prefKey = 'theme_mode';
  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  ThemeController._(this._mode);

  static Future<ThemeController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_prefKey) ?? ThemeMode.system.index;
    return ThemeController._(ThemeMode.values[index]);
  }

  void setMode(ThemeMode newMode) async {
    _mode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, newMode.index);
    notifyListeners();
  }
}

// ---- Hier deine Themes ---- //

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
    useMaterial3: true,
    cardTheme: const CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent, brightness: Brightness.dark),
    useMaterial3: true,
    cardTheme: const CardTheme(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}
