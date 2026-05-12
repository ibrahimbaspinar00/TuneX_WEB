import 'package:flutter/material.dart';

import 'app_design_system.dart';

class ProfessionalTheme {
  static Color get primaryColor => AppDesignSystem.primary;
  static Color get primaryLight => AppDesignSystem.primary;
  static Color get primaryDark => AppDesignSystem.background;

  static Color get secondaryColor => AppDesignSystem.accentBlue;
  static Color get secondaryLight => AppDesignSystem.accentBlue;
  static Color get secondaryDark => AppDesignSystem.surface;

  static Color get accentColor => AppDesignSystem.primary;
  static Color get accentLight => AppDesignSystem.accentBlue;
  static const Color accentDark = AppColors.brandOrangeDark;

  static Color get backgroundColor => AppDesignSystem.background;
  static Color get surfaceColor => AppDesignSystem.surface;
  static Color get cardColor => AppDesignSystem.surfaceElevated;

  static Color get textPrimary => AppDesignSystem.textPrimary;
  static Color get textSecondary => AppDesignSystem.textSecondary;
  static Color get textHint => AppDesignSystem.textTertiary;

  static Color get successColor => AppDesignSystem.success;
  static Color get warningColor => AppDesignSystem.warning;
  static Color get errorColor => AppDesignSystem.error;
  static Color get infoColor => AppDesignSystem.accentBlue;

  static ThemeData get lightTheme => AppDesignSystem.lightTheme;
  static ThemeData get darkTheme => AppDesignSystem.darkTheme;
}
