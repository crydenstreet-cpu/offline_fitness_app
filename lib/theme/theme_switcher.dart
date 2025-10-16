// lib/theme/theme_switcher.dart
import 'package:flutter/material.dart';

/// Öffentlicher Inherited-Helper, um ThemeMode global zu schalten.
/// Der State (hell/dunkel) lebt in main.dart; Settings ruft dann setDark(true/false).
class ThemeSwitcher extends InheritedWidget {
  final void Function(bool dark) setDark;

  const ThemeSwitcher({
    super.key,
    required this.setDark,
    required super.child,
  });

  static ThemeSwitcher? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeSwitcher>();

  @override
  bool updateShouldNotify(covariant ThemeSwitcher oldWidget) => false;
}
