import 'package:flutter/material.dart';

/// AMOLED Black + Electric Purple Theme
class AppColors {
  static const black   = Color(0xFF000000);
  static const surface = Color(0xFF0A0A0A);
  static const surface2= Color(0xFF121212);
  static const purple  = Color(0xFF7C4DFF);
  static const mint    = Color(0xFF00FFC6);
  static const text    = Colors.white;
  static const textMuted = Color(0xCCFFFFFF);

  /// Alias, damit Komponenten `AppColors.primary` nutzen können:
  static const primary = purple;
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.black,
    cardColor: AppColors.surface,
    splashFactory: InkSparkle.splashFactory,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.mint,
      surface: AppColors.surface,
      background: AppColors.black,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
      titleMedium:  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
      bodyMedium:   const TextStyle(fontSize: 14, color: AppColors.textMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.black,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: StadiumBorder(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.mint,
        side: const BorderSide(color: AppColors.mint, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),
    dividerTheme: const DividerThemeData(color: Colors.white10, thickness: 1),
    cardTheme: CardThemeData( // <-- CardThemeData statt CardTheme
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
  );
}

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;
  final Widget? fab;
  const AppScaffold({super.key, this.appBar, required this.body, this.bottom, this.fab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: fab,
      bottomNavigationBar: bottom,
      body: body,
    );
  }
}
