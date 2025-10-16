import 'package:flutter/material.dart';

/// -------------------------------
/// Farben (Grau/Schwarz/Rot-Stil)
/// + Backwards-Compat Aliase
/// -------------------------------
class AppColors {
  // Akzent
  static const Color red = Color(0xFFE53935);
  static const Color redDark = Color(0xFFB71C1C);

  // Dark
  static const Color darkBgTop = Color(0xFF0C0D10);
  static const Color darkBgBottom = Color(0xFF15171C);
  static const Color darkSurface = Color(0xFF1C1F26);
  static const Color darkSurface2 = Color(0xFF232833);

  // Light
  static const Color lightBgTop = Color(0xFFF8F9FB);
  static const Color lightBgBottom = Color(0xFFF1F3F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF6F7FB);

  // Text
  static const Color textDark = Color(0xFFEDEFF4);
  static const Color textDarkMuted = Color(0xFFB7BDCA);
  static const Color textLight = Color(0xFF101318);
  static const Color textLightMuted = Color(0xFF5E6676);

  // Aliase für alten Code
  static const Color primary = red;
  static const Color surface2 = lightSurface2;
  static const Color text = textLight;
}

/// Theme-Extension: verrät GradientBackground, ob Light/Dark
class _AppThemeX extends ThemeExtension<_AppThemeX> {
  final bool light;
  const _AppThemeX({required this.light});
  @override
  _AppThemeX copyWith({bool? light}) => _AppThemeX(light: light ?? this.light);
  @override
  _AppThemeX lerp(ThemeExtension<_AppThemeX>? other, double t) => this;
}

bool _isLight(BuildContext context) =>
    Theme.of(context).extension<_AppThemeX>()?.light ?? true;

/// -------------------------
/// Themes
/// -------------------------
ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    brightness: Brightness.light,
  );

  final scheme = ColorScheme.light(
    primary: AppColors.red,
    onPrimary: Colors.white,
    secondary: Colors.black87,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textLight,
    background: AppColors.lightBgBottom,
    onBackground: AppColors.textLight,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBgBottom,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textLight,
    ),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.red,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      _AppThemeX(light: true),
    ],
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    brightness: Brightness.dark,
  );

  final scheme = ColorScheme.dark(
    primary: AppColors.red,
    onPrimary: Colors.white,
    secondary: AppColors.textDarkMuted,
    onSecondary: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.textDark,
    background: AppColors.darkBgBottom,
    onBackground: AppColors.textDark,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBgBottom,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
    ),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.red,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      _AppThemeX(light: false),
    ],
  );
}

// Legacy-Fallback
ThemeData buildAppTheme() => buildLightTheme();

/// -------------------------
/// Gradient-Hintergrund
/// -------------------------
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);
    final top = isLight ? AppColors.lightBgTop : AppColors.darkBgTop;
    final bottom = isLight ? AppColors.lightBgBottom : AppColors.darkBgBottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: child,
    );
  }
}

/// -------------------------
/// AppScaffold (mit Drawer)
/// -------------------------
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;
  final Widget? fab;
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
      drawer: drawer,
      appBar: appBar,
      body: GradientBackground(child: SafeArea(child: body)),
      bottomNavigationBar: bottom,
      floatingActionButton: fab,
    );
  }
}

/// -------------------------
/// Flache Card
/// -------------------------
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

    @override
    Widget build(BuildContext context) {
      final surf = Theme.of(context).colorScheme.surface;
      return Material(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      );
    }
}

/// -------------------------
/// 3D-Card (optional)
/// -------------------------
class AppCard3D extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback? onTap;
  final bool highlight;
  const AppCard3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [const Color(0xFFFFFFFF), const Color(0xFFF3F5FA)]
              : [const Color(0xFF262B36), const Color(0xFF1B2029)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.18 : 0.45),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: (isLight ? Colors.white70 : Colors.white12),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(-6, -6),
          ),
        ],
        border: Border.all(
          color: highlight
              ? AppColors.red.withOpacity(0.5)
              : (isLight ? Colors.black12 : Colors.white12),
          width: highlight ? 1.4 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
