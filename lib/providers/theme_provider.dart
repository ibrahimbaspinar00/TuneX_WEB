import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class ThemeProvider extends ThemeController {
  ThemeProvider({ThemeMode initialThemeMode = ThemeMode.light})
      : super(initialThemeMode: initialThemeMode);
}
