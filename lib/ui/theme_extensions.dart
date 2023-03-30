import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Color get primary => colorScheme.primary;

  Color get primaryContainer => colorScheme.primaryContainer;

  Color get onPrimary => colorScheme.onPrimary;

  Color get secondary => colorScheme.secondary;

  Color get secondaryContainer => colorScheme.secondaryContainer;

  Color get onSecondary => colorScheme.onSecondary;

  Color get surface => colorScheme.surface;

  Color get onSurface => colorScheme.onSurface;

  Color get background => colorScheme.background;

  Color get onBackground => colorScheme.onBackground;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
