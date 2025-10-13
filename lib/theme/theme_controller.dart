import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zentraler Theme-Controller (persistiert mit SharedPreferences)
class ThemeController extends ChangeNotifier {
  static const _kMode = 'theme_mode'; // 'system' | 'light' | 'dark'

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Du kannst diese Themes beliebig anpassen – sie sind unabhängig von design.dart.
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0ABAB5),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        cardTheme: CardTheme(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00E0C6),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C1014),
        cardTheme: CardTheme(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
      );

  /// Initialisieren + gespeicherten Zustand laden
  static Future<ThemeController> init() async {
    final c = ThemeController();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMode);
    switch (raw) {
      case 'light':
        c._mode = ThemeMode.light;
        break;
      case 'dark':
        c._mode = ThemeMode.dark;
        break;
      default:
        c._mode = ThemeMode.system;
    }
    return c;
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    switch (m) {
      case ThemeMode.light:
        await prefs.setString(_kMode, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_kMode, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_kMode, 'system');
        break;
    }
  }
}
