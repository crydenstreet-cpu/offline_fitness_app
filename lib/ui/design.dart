import 'package:flutter/material.dart';

class AppColors {
  static const bg        = Color(0xFF0B0D0E);
  static const surface   = Color(0xFF121416);
  static const surface2  = Color(0xFF1A1E22);
  static const primary   = Color(0xFF00E0C6);
  static const secondary = Color(0xFF7AE582);
  static const text      = Colors.white;
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
      titleTextStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 18),
    ),
    cardTheme: const CardTheme(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
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
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface2),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
      ),
    ),
    dialogBackgroundColor: AppColors.surface,
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Einheitliches Scaffold (sorgt für identische Hintergründe)
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;
  const AppScaffold({super.key, this.appBar, required this.body, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: bottom,
    );
  }
}
