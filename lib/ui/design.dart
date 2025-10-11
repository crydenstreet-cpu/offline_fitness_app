import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F1115);           // tiefer Dark-Background
  static const surface = Color(0xFF171A20);      // Karten/Paneele
  static const surface2 = Color(0xFF1E232B);
  static const primary = Color(0xFF00E0C6);      // Cyan-Akzent (aus deinem Stil)
  static const text = Colors.white;
  static const textMuted = Colors.white70;
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFFFC107);
  static const danger  = Color(0xFFE74C3C);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.surface,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.surface2,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary, foregroundColor: Colors.black),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),
  );
}

/// Hintergrund mit sanftem Verlauf + optionaler Scrollbar
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E0F13), Color(0xFF12151B)],
          ),
        ),
        child: body,
      ),
    );
  }
}
