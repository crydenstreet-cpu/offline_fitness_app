import 'package:flutter/material.dart';

class AppColors {
  static const bg        = Color(0xFF0B0D0E);
  static const surface   = Color(0xFF121416);
  static const surface2  = Color(0xFF1A1E22);
  static const primary   = Color(0xFF00E0C6);
  static const secondary = Color(0xFF7AE582);
  static const text      = Colors.white;
  static const textMuted = Colors.white54; // <- für components.dart
}

ThemeData buildAppTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    background: AppColors.bg,
    surface: AppColors.surface,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: cs,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),

    // Flutter 3.35 erwartet hier CardThemeData (nicht CardTheme)
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),

    // In neueren Flutter-Versionen: MaterialStatePropertyAll statt WidgetStatePropertyAll
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStatePropertyAll(AppColors.surface2),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ),

    dialogBackgroundColor: AppColors.surface,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Einheitliches Scaffold – jetzt mit FAB-Support
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;
  final Widget? fab; // <- hinzugefügt

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottom,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: bottom,
      floatingActionButton: fab, // <- durchgereicht

      import 'package:flutter/material.dart';

class AppColors {
  // Sportlich-modern: Türkis/Anthrazit
  static const Color primary = Color(0xFF00E0C6);
  static const Color secondary = Color(0xFF66FFE9);

  static const Color bgDarkTop = Color(0xFF0C1014);
  static const Color bgDarkBottom = Color(0xFF1A1F26);

  static const Color bgLightTop = Color(0xFFF5FFFF);
  static const Color bgLightBottom = Color(0xFFE6FFFC);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: Colors.white,
    background: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
    cardTheme: const CardTheme().copyWith(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: const Color(0xFF10151B),
    background: const Color(0xFF0E1318),
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardTheme().copyWith(
      color: const Color(0xFF151B22),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

/// Hintergrund mit Gradient, abhängig vom Theme (hell/dunkel)
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = isDark ? AppColors.bgDarkTop : AppColors.bgLightTop;
    final bottom = isDark ? AppColors.bgDarkBottom : AppColors.bgLightBottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

/// Minimaler AppScaffold, der die GradientBackground nutzt.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;
  final Widget? fab;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottom,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottom,
        floatingActionButton: fab,
      ),
    );
  }
}

