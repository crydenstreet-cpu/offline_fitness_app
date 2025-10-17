// lib/ui/design.dart
import 'package:flutter/material.dart';

class AppColors {
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

  // Backwards-Compat
  static const Color primary = red;
  static const Color surface2 = lightSurface2;
  static const Color text = textLight;
}

/// ---------- LIGHT THEME ----------
ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    // etwas kompakter global
    visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    brightness: Brightness.light,
  );

  const scheme = ColorScheme.light(
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

    // SCHLANKERE APPBAR
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textLight,
      toolbarHeight: 40, // << schlanker Balken
      titleSpacing: 8,
      titleTextStyle: TextStyle(
        fontSize: 16, // << kleiner
        fontWeight: FontWeight.w800,
        color: AppColors.textLight,
      ),
      iconTheme: IconThemeData(size: 20), // << kleiner
    ),

    // Schlankere Tabs
    tabBarTheme: const TabBarThemeData(
      labelPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 13),
      dividerColor: Colors.transparent,
    ),

    // Karten
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    // Buttons etwas dichter
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.red,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    // ListTiles kompakter
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 6,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: AppColors.textLight,
      textColor: AppColors.textLight,
    ),

    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
    ),
  );
}

/// ---------- DARK THEME ----------
ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    brightness: Brightness.dark,
  );

  const scheme = ColorScheme.dark(
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
      toolbarHeight: 40, // << schlanker Balken
      titleSpacing: 8,
      titleTextStyle: TextStyle(
        fontSize: 16, // << kleiner
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
      iconTheme: IconThemeData(size: 20), // << kleiner
    ),

    tabBarTheme: const TabBarThemeData(
      labelPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 13),
      dividerColor: Colors.transparent,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 6,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: AppColors.textDark,
      textColor: AppColors.textDark,
    ),

    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    ),
  );
}

ThemeData buildAppTheme() => buildLightTheme();

/// Verlaufshintergrund
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final top = isLight ? AppColors.lightBgTop : AppColors.darkBgTop;
    final bottom = isLight ? AppColors.lightBgBottom : AppColors.darkBgBottom;

    return DecoratedBox(
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

/// AppScaffold – transparenter Hintergrund für Verlauf
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
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        // oben SafeArea anlassen, damit nix in die Statusbar rutscht
        child: const SafeArea(top: true, bottom: true, child: SizedBox.shrink()),
      ).copyWithBody(body), // kleiner Helper unten
      bottomNavigationBar: bottom,
      floatingActionButton: fab,
    );
  }
}

// Kleiner Helper, um im AppScaffold das Kind einzusetzen,
// ohne den Gradient-Block oben aufzublasen.
extension on GradientBackground {
  Widget copyWithBody(Widget body) => GradientBackground(child: SafeArea(child: body));
}

/// Flat Card
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
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 3D Card
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isLight
              ? [const Color(0xFFFFFFFF), const Color(0xFFF3F5FA)]
              : [const Color(0xFF262B36), const Color(0xFF1B2029)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.18 : 0.45),
            blurRadius: 22, spreadRadius: 1, offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: (isLight ? Colors.white70 : Colors.white12),
            blurRadius: 18, spreadRadius: -8, offset: const Offset(-6, -6),
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
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 3D Button
class AppButton3D extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
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
    final isLight = Theme.of(context).brightness == Brightness.light;

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
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [bgA, bgB],
          ),
          boxShadow: _down
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.22 : 0.55),
                    blurRadius: 10, offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.22 : 0.55),
                    blurRadius: 18, offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(isLight ? 0.35 : 0.08),
                    blurRadius: 10, spreadRadius: -6, offset: const Offset(0, -4),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

/// Sektionstitel
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final muted = isLight ? AppColors.textLightMuted : AppColors.textDarkMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
