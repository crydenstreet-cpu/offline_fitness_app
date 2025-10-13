import 'package:flutter/material.dart';

/// -------------------------------
/// Farb-System (Grey/Black + Red)
/// -------------------------------
class AppColors {
  // Akzent
  static const Color red      = Color(0xFFE53935);
  static const Color redSoft  = Color(0xFFFF6E6E);

  // Light
  static const Color lightBgTop    = Color(0xFFF7F7F8);
  static const Color lightBgBottom = Color(0xFFEDEEEF);
  static const Color lightCard     = Colors.white;
  static const Color lightText     = Color(0xFF0F1115);
  static const Color lightSubtle   = Color(0xFF6B717A);
  static const Color lightStroke   = Color(0xFFE6E8EB);

  // Dark
  static const Color darkBgTop     = Color(0xFF0B0D10);
  static const Color darkBgBottom  = Color(0xFF14181D);
  static const Color darkCard      = Color(0xFF1B2128);
  static const Color darkText      = Color(0xFFEEF1F5);
  static const Color darkSubtle    = Color(0xFF9AA3AD);
  static const Color darkStroke    = Color(0xFF2A313A);
}

/// ---------------------------------------
/// Light/Dark ThemeData (Material 3-ready)
/// ---------------------------------------
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    brightness: Brightness.light,
    primary: AppColors.red,
    secondary: AppColors.redSoft,
    surface: AppColors.lightCard,
    background: AppColors.lightBgBottom,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.lightText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent, // wir legen Gradient drunter
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
      titleLarge:   TextStyle(fontWeight: FontWeight.w700),
      titleMedium:  TextStyle(fontWeight: FontWeight.w600),
      bodyMedium:   TextStyle(height: 1.35),
      labelLarge:   TextStyle(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText),
      iconTheme: IconThemeData(color: AppColors.lightText.withOpacity(.9)),
    ),
    cardTheme: const CardTheme(
      color: AppColors.lightCard,
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: AppColors.lightStroke),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.red.withOpacity(.9), width: 1.6),
      ),
      labelStyle: const TextStyle(color: AppColors.lightSubtle),
      hintStyle: const TextStyle(color: AppColors.lightSubtle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightText,
        side: const BorderSide(color: AppColors.lightStroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.red,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.red,
      unselectedItemColor: AppColors.lightSubtle,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.lightStroke,
    iconTheme: const IconThemeData(size: 22),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    brightness: Brightness.dark,
    primary: AppColors.red,
    secondary: AppColors.redSoft,
    surface: AppColors.darkCard,
    background: AppColors.darkBgBottom,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.darkText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
      titleLarge:   TextStyle(fontWeight: FontWeight.w700),
      titleMedium:  TextStyle(fontWeight: FontWeight.w600),
      bodyMedium:   TextStyle(height: 1.35),
      labelLarge:   TextStyle(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText),
      iconTheme: IconThemeData(color: AppColors.darkText.withOpacity(.9)),
    ),
    cardTheme: const CardTheme(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: AppColors.darkStroke),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.red.withOpacity(.9), width: 1.6),
      ),
      labelStyle: const TextStyle(color: AppColors.darkSubtle),
      hintStyle: const TextStyle(color: AppColors.darkSubtle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        side: const BorderSide(color: AppColors.darkStroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.red,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.red,
      unselectedItemColor: AppColors.darkSubtle,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.darkStroke,
    iconTheme: const IconThemeData(size: 22),
  );
}

/// ----------------------------------------------
/// Gradient-Hintergrund (hell/dunkel automatisch)
/// ----------------------------------------------
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = isDark ? AppColors.darkBgTop : AppColors.lightBgTop;
    final bottom = isDark ? AppColors.darkBgBottom : AppColors.lightBgBottom;

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

/// --------------------------------------------------------
/// AppScaffold: behält deine BottomNav, fügt nur Styles hinzu
/// --------------------------------------------------------
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
        body: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: body,
        ),
        bottomNavigationBar: bottom,
        floatingActionButton: fab,
      ),
    );
  }
}
