import 'package:flutter/material.dart';

/// Zentrale Farben (Sportlich-Modern: Türkis/Anthrazit)
class AppColors {
  static const Color primary = Color(0xFF00E0C6);
  static const Color secondary = Color(0xFF66FFE9);

  // Hintergründe für Gradient
  static const Color bgDarkTop = Color(0xFF0C1014);
  static const Color bgDarkBottom = Color(0xFF1A1F26);

  static const Color bgLightTop = Color(0xFFF5FFFF);
  static const Color bgLightBottom = Color(0xFFE6FFFC);

  // Karten-/Flächenfarben
  static const Color surfaceDark = Color(0xFF10151B);
  static const Color surfaceDark2 = Color(0xFF151B22);

  // von UI-Komponenten referenziert
  static const Color surface2 = surfaceDark2;       // Alias
  static const Color textMuted = Colors.white70;    // für Untertitel
}

/// Light Theme (Material 3 + transparente Scaffold-Farbe für Gradient)
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
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
    ),
  );
}

/// Dark Theme (Material 3 + transparente Scaffold-Farbe für Gradient)
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceDark,
    background: Color(0xFF0E1318),
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
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
    ),
  );
}

/// Kompatibler Wrapper (falls irgendwo noch buildAppTheme() genutzt wird)
ThemeData buildAppTheme() => buildDarkTheme();

/// Hintergrund mit Gradient (hell/dunkel abhängig vom Theme)
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

/// Scaffold, das automatisch den Gradient-Hintergrund nutzt
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
