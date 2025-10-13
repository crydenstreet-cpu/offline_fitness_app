import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeVariant { neo, flat } // nur als Beispiel-Option

class ThemeController extends ChangeNotifier {
  static const _kThemeModeKey = 'theme_mode';
  static const _kVariantKey   = 'theme_variant';

  ThemeMode _mode = ThemeMode.system;
  ThemeVariant _variant = ThemeVariant.neo;

  ThemeMode get mode => _mode;
  ThemeVariant get variant => _variant;

  ThemeData get lightTheme => _buildLightTheme();
  ThemeData get darkTheme  => _buildDarkTheme();

  ThemeController._();

  /// Initialisiert Controller + lädt gespeicherte Einstellungen.
  static Future<ThemeController> init() async {
    final c = ThemeController._();
    final prefs = await SharedPreferences.getInstance();
    final modeIdx = prefs.getInt(_kThemeModeKey);
    final varIdx  = prefs.getInt(_kVariantKey);

    if (modeIdx != null && modeIdx >= 0 && modeIdx < ThemeMode.values.length) {
      c._mode = ThemeMode.values[modeIdx];
    }
    if (varIdx != null && varIdx >= 0 && varIdx < ThemeVariant.values.length) {
      c._variant = ThemeVariant.values[varIdx];
    }
    return c;
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, m.index);
    notifyListeners();
  }

  Future<void> setVariant(ThemeVariant v) async {
    _variant = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kVariantKey, v.index);
    notifyListeners();
  }

  // ---------- Themes ----------

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00E0C6), // Primärfarbe (türkis)
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      cardTheme: const CardThemeData(            // <-- WICHTIG: CardThemeData statt CardTheme
        elevation: 8,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );

    // Optional: leichte „3D“-Anmutung (Schatten/Border)
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: base.colorScheme.primary,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00E0C6),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1116),
      cardTheme: const CardThemeData(            // <-- WICHTIG: CardThemeData statt CardTheme
        elevation: 10,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: base.colorScheme.primary,
      ),
    );
  }
}
