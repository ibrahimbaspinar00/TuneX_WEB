import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialThemeMode = ThemeMode.light})
      : _themeMode = initialThemeMode,
        _isInitialized = true;

  ThemeMode _themeMode;
  bool _isInitialized;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get isDarkMode => ThemeService.isDarkForMode(_themeMode);
  bool get isLightMode => !isDarkMode;

  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.light:
        return 'Açık Tema';
    }
  }

  Future<void> refreshFromStorage() async {
    _isInitialized = false;
    notifyListeners();

    try {
      await ThemeService.loadTheme();
      _themeMode = ThemeService.themeMode;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();
    await ThemeService.setThemeMode(mode);
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
