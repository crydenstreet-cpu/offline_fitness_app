import 'package:flutter/material.dart';

/// Optional: einfacher Controller, falls du später live umschalten willst.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

/// ---- LIGHT / DARK THEMES ----
/// Diese Namen nutzt du bereits an anderen Stellen (buildLightTheme / buildDarkTheme).

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFE53935), // Rotton (anpassbar)
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData( // <-- wichtig: CardThemeData statt CardTheme
      elevation: 2,
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFE53935), // Rotton (anpassbar)
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0E1116),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData( // <-- wichtig: CardThemeData statt CardTheme
      elevation: 3,
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
