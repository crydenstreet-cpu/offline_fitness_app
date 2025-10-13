// lib/ui/design.dart
import 'package:flutter/material.dart';

/// -------------------------------
/// Farben (Grau/Schwarz/Rot-Stil)
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
}

/// ----------------------------------------------------
/// THEME (einheitlich, Material 3, fette Akzentfarbe Rot)
/// ----------------------------------------------------
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
  );

  // Light
  final lightScheme = ColorScheme.light(
    primary: AppColors.red,
    onPrimary: Colors.white,
    secondary: Colors.black87,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textLight,
    background: AppColors.lightBgBottom,
    onBackground: AppColors.textLight,
  );

  // Dark
  final darkScheme = ColorScheme.dark(
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
    colorScheme: lightScheme,
    scaffoldBackgroundColor: AppColors.lightBgBottom,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textLight,
    ),
    cardTheme: const CardTheme(
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
  ).copyWith(
    // Automatisch Dark-Mode support – du verwendest nur buildAppTheme()
    // (MaterialApp nimmt system brightness, wir liefern beide Schemes.)
    brightness: Brightness.light,
    extensions: <ThemeExtension<dynamic>>[
      _AppThemeX(light: lightScheme, dark: darkScheme),
    ],
  );
}

/// Kleiner Trick: wir hängen beide Farbschemata als Extension an,
/// damit GradientBackground im Dark/Light die richtigen Töne findet.
class _AppThemeX extends ThemeExtension<_AppThemeX> {
  final ColorScheme light;
  final ColorScheme dark;
  const _AppThemeX({required this.light, required this.dark});

  @override
  _AppThemeX copyWith({ColorScheme? light, ColorScheme? dark}) =>
      _AppThemeX(light: light ?? this.light, dark: dark ?? this.dark);

  @override
  _AppThemeX lerp(ThemeExtension<_AppThemeX>? other, double t) => this;
}

_AppThemeX appThemeX(BuildContext context) =>
    Theme.of(context).extension<_AppThemeX>()!;

/// ------------------------------------
/// Hintergrund mit leichtem Verlauf
/// ------------------------------------
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = isDark ? AppColors.darkBgTop : AppColors.lightBgTop;
    final bottom = isDark ? AppColors.darkBgBottom : AppColors.lightBgBottom;

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

/// ------------------------------------
/// AppScaffold – Wrapper für alle Screens
/// ------------------------------------
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

/// ------------------------------------
/// Flat-Card (bestehende Komponente)
/// ------------------------------------
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

/// ------------------------------------
/// 3D-Card – kräftiger Look (Schatten + Glanzkante)
/// ------------------------------------
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bg2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF262B36) : const Color(0xFFFFFFFF),
            isDark ? const Color(0xFF1B2029) : const Color(0xFFF3F5FA),
          ],
        ),
        boxShadow: [
          // tiefer Schatten unten rechts
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
          // weicher Lichtschein oben links
          BoxShadow(
            color: (isDark ? Colors.white12 : Colors.white70),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(-6, -6),
          ),
        ],
        border: Border.all(
          color: highlight
              ? AppColors.red.withOpacity(0.5)
              : (isDark ? Colors.white12 : Colors.black12),
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

/// ------------------------------------
/// 3D-Button – kräftig, mit Press-Animation
/// ------------------------------------
class AppButton3D extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled; // true = rot gefüllt; false = neutral 3D
  const AppButton3D({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
  });

  @override
  State<AppButton3D> createState() => _AppButton3DState();
}

class _AppButton3DState extends State<AppButton3D> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgA = widget.filled
        ? AppColors.red
        : (isDark ? const Color(0xFF2A303B) : const Color(0xFFFFFFFF));
    final bgB = widget.filled
        ? AppColors.redDark
        : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F3F8));

    final fg = widget.filled
        ? Colors.white
        : (isDark ? AppColors.textDark : AppColors.textLight);

    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..translate(0.0, _down ? 2.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgA, bgB],
          ),
          boxShadow: _down
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.55 : 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.55 : 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  // Schimmerkante
                  BoxShadow(
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.35),
                    blurRadius: 10,
                    spreadRadius: -6,
                    offset: const Offset(0, -4),
                  ),
                ],
          border: Border.all(
            color: widget.filled
                ? Colors.white.withOpacity(0.18)
                : (isDark ? Colors.white10 : Colors.black12),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------
/// Kleine Utility-Header (optional, falls du sie brauchst)
/// ----------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textDarkMuted
        : AppColors.textLightMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
