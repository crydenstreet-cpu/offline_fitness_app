// lib/ui/design.dart
import 'package:flutter/material.dart';

/// -------------------------------
/// Farben (Grau/Schwarz/Rot-Stil)
/// + Backwards-Compat Aliase (primary, surface2, text)
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

  // ===== Backwards-Compat Aliase (für bestehenden Code) =====
  static const Color primary = red;            // wurde in alten Screens genutzt
  static const Color surface2 = lightSurface2; // z. B. für CircleAvatar
  static const Color text = textLight;         // Standard-Textfarbe (Light)
}

/// Marker-Extension um hell/dunkel für den Gradient zu erkennen
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

/// ----------------------------------------------------
/// THEME (Material 3, kräftiger Rot-Akzent)
/// ----------------------------------------------------
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

/// Falls irgendwo noch buildAppTheme() genutzt wird
ThemeData buildAppTheme() => buildLightTheme();

/// ------------------------------------
/// Hintergrund mit leichtem Verlauf
/// ------------------------------------
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

/// ------------------------------------
/// AppScaffold – mit optionalem Drawer
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
/// Flat-Card
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
/// 3D-Card – kräftiger Look
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

/// ------------------------------------
/// 3D-Button – kräftig
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
    final isLight = _isLight(context);

    final bgA = widget.filled
        ? AppColors.red
        : (isLight ? const Color(0xFFFFFFFF) : const Color(0xFF2A303B));
    final bgB = widget.filled
        ? AppColors.redDark
        : (isLight ? const Color(0xFFF1F3F8) : const Color(0xFF1E2430));

    final fg = widget.filled
        ? Colors.white
        : (isLight ? AppColors.textLight : AppColors.textDark);

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
                    color: Colors.black.withOpacity(isLight ? 0.22 : 0.55),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.22 : 0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(isLight ? 0.35 : 0.08),
                    blurRadius: 10,
                    spreadRadius: -6,
                    offset: const Offset(0, -4),
                  ),
                ],
          border: Border.all(
            color: widget.filled
                ? Colors.white.withOpacity(0.18)
                : (isLight ? Colors.black12 : Colors.white10),
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
/// Kleine Utility-Header
/// ----------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);
    final muted = isLight ? AppColors.textLightMuted : AppColors.textDarkMuted;
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
