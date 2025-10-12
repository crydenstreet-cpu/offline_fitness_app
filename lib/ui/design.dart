// lib/ui/design.dart
import 'package:flutter/material.dart';

/// Farben & Gradients
class AppColors {
  // Brand
  static const Color primary   = Color(0xFF00E0C6);
  static const Color secondary = Color(0xFF00B2A9);

  // Text
  static const Color text       = Colors.white;
  static const Color textMuted  = Colors.white70;

  // Flächen
  static const Color surface2 = Color(0xFF1E2730);

  // Gradients (Light/Dark)
  static const Color bgDarkTop     = Color(0xFF0C1014);
  static const Color bgDarkBottom  = Color(0xFF1A1F26);
  static const Color bgLightTop    = Color(0xFFF5FFFF);
  static const Color bgLightBottom = Color(0xFFE6FFFC);
}

/// Ein Theme (du kannst später Light/Dark trennen – aktuell einheitlich)
ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    scaffoldBackgroundColor: Colors.transparent, // wichtig für Gradient
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardTheme().copyWith(
      color: const Color(0xFF151C22),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    useMaterial3: true,
  );
}

/// Hintergrund mit Gradient (passt sich an Brightness an)
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top    = isDark ? AppColors.bgDarkTop    : AppColors.bgLightTop;
    final bottom = isDark ? AppColors.bgDarkBottom : AppColors.bgLightBottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: child,
    );
  }
}

/// Einheitliches Scaffold (AppBar, Drawer, FAB, BottomBar + Gradient)
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;
  final FloatingActionButton? fab;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottom,
    this.fab,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: GradientBackground(child: SafeArea(child: body)),
      bottomNavigationBar: bottom,
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Card mit standardisiertem Padding / Look
class AppCard extends StatelessWidget {
  final Widget child;
  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}
