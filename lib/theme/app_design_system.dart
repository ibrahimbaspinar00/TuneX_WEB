import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/theme_service.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.isDark,
    required this.background,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInteractive,
    required this.modalSurface,
    required this.inputFill,
    required this.navSurface,
    required this.accent,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.accentSoft,
    required this.accentGlow,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.borderSubtle,
    required this.borderStrong,
    required this.divider,
    required this.shadow,
    required this.hover,
  });

  final bool isDark;
  final Color background;
  final Color backgroundSecondary;
  final Color backgroundTertiary;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInteractive;
  final Color modalSurface;
  final Color inputFill;
  final Color navSurface;
  final Color accent;
  final Color accentSecondary;
  final Color accentTertiary;
  final Color accentSoft;
  final Color accentGlow;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;
  final Color borderSubtle;
  final Color borderStrong;
  final Color divider;
  final Color shadow;
  final Color hover;

  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [background, backgroundSecondary, backgroundTertiary],
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [backgroundSecondary, surface, const Color(0xFF0A1022)]
            : [const Color(0xFFF7FCFF), surface, const Color(0xFFEFFBF7)],
      );

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [accent, accentSecondary, accentTertiary]
            : [accent, const Color(0xFF56D7C4), accentSecondary],
      );

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.28 : 0.08),
          blurRadius: isDark ? 22 : 18,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.34 : 0.12),
          blurRadius: isDark ? 28 : 22,
          offset: const Offset(0, 12),
        ),
      ];

  List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accentGlow.withValues(alpha: isDark ? 0.22 : 0.14),
          blurRadius: isDark ? 34 : 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.30 : 0.10),
          blurRadius: isDark ? 36 : 24,
          offset: const Offset(0, 16),
        ),
      ];

  @override
  AppThemeColors copyWith({
    bool? isDark,
    Color? background,
    Color? backgroundSecondary,
    Color? backgroundTertiary,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceInteractive,
    Color? modalSurface,
    Color? inputFill,
    Color? navSurface,
    Color? accent,
    Color? accentSecondary,
    Color? accentTertiary,
    Color? accentSoft,
    Color? accentGlow,
    Color? success,
    Color? warning,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? borderSubtle,
    Color? borderStrong,
    Color? divider,
    Color? shadow,
    Color? hover,
  }) {
    return AppThemeColors(
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundTertiary: backgroundTertiary ?? this.backgroundTertiary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceInteractive: surfaceInteractive ?? this.surfaceInteractive,
      modalSurface: modalSurface ?? this.modalSurface,
      inputFill: inputFill ?? this.inputFill,
      navSurface: navSurface ?? this.navSurface,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentTertiary: accentTertiary ?? this.accentTertiary,
      accentSoft: accentSoft ?? this.accentSoft,
      accentGlow: accentGlow ?? this.accentGlow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      hover: hover ?? this.hover,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      backgroundTertiary:
          Color.lerp(backgroundTertiary, other.backgroundTertiary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceInteractive:
          Color.lerp(surfaceInteractive, other.surfaceInteractive, t)!,
      modalSurface: Color.lerp(modalSurface, other.modalSurface, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      navSurface: Color.lerp(navSurface, other.navSurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentTertiary: Color.lerp(accentTertiary, other.accentTertiary, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appTheme =>
      Theme.of(this).extension<AppThemeColors>() ?? AppDesignSystem.lightColors;
}

class AppColors {
  const AppColors._();

  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color brandCyan = Color(0xFF00D1FF);
  static const Color brandOrange = Color(0xFFFF6A00);
  static const Color brandOrangeDark = Color(0xFFE85F00);
  static const Color brandMint = Color(0xFF56D7C4);
  static const Color brandPurple = Color(0xFF8B5CF6);
  static const Color brandPink = Color(0xFFEC4899);

  static const Color ink950 = Color(0xFF0A0A0A);
  static const Color ink925 = Color(0xFF0B0D10);
  static const Color ink900 = Color(0xFF0F0F0F);
  static const Color ink850 = Color(0xFF111111);
  static const Color ink800 = Color(0xFF1A1A1A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF2A3340);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF8E98A8);
  static const Color slate300 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFC7CDD6);
  static const Color slate100 = Color(0xFFDDE6EE);
  static const Color slate75 = Color(0xFFE0E0E0);
  static const Color slate50 = Color(0xFFEFF4F8);
  static const Color slate25 = Color(0xFFF3F4F6);
  static const Color surfaceLight = Color(0xFFF8FAFC);

  static const Color success = Color(0xFF18C964);
  static const Color successStrong = Color(0xFF228B22);
  static const Color successSoft = Color(0xFFE8FBF2);
  static const Color successSoftAlt = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFFFB020);
  static const Color warningStrong = Color(0xFFFF8C42);
  static const Color warningSoft = Color(0xFFFFF5E5);
  static const Color warningSoftAlt = Color(0xFFFFF4E6);

  static const Color error = Color(0xFFEF4444);
  static const Color errorStrong = Color(0xFFFF5B6E);
  static const Color errorSoft = Color(0xFFFFECEC);
  static const Color errorSoftAlt = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF0066CC);
  static const Color infoSoft = Color(0xFFEAF8FF);
  static const Color infoSoftAlt = Color(0xFFEFF6FF);
}

class AppDesignSystem {
  static const String brandName = 'TuneX';
  static const String brandTagline = 'Premium Tuning Marketplace';

  static AppThemeColors get activeColors {
    final isDark = ThemeService.isDarkForMode(ThemeService.themeMode);
    return isDark ? darkColors : lightColors;
  }

  static Color get primary => activeColors.accent;
  static Color get accentBlue => activeColors.accent;
  static Color get accent => activeColors.accent;
  static Color get success => activeColors.success;
  static Color get warning => activeColors.warning;
  static Color get error => activeColors.error;
  static Color get favorite => activeColors.error;
  static Color get discount => AppColors.success;
  static Color get newBadge => activeColors.accent;
  static Color get info => activeColors.accent;

  static Color get primaryContainer => activeColors.accentSoft;
  static Color get background => activeColors.background;
  static Color get surface => activeColors.surface;
  static Color get surfaceElevated => activeColors.surfaceElevated;
  static Color get surfaceVariant => activeColors.surfaceInteractive;
  static Color get textPrimary => activeColors.textPrimary;
  static Color get textSecondary => activeColors.textSecondary;
  static Color get textTertiary => activeColors.textMuted;
  static Color get textDisabled => activeColors.textMuted;
  static Color get textOnPrimary => activeColors.textInverse;
  static Color get borderLight => activeColors.borderSubtle;
  static Color get borderMedium => activeColors.borderStrong;
  static Color get borderDark => activeColors.borderStrong;
  static Color get successLight =>
      activeColors.isDark ? AppColors.successSoftAlt : AppColors.successSoft;
  static Color get warningLight =>
      activeColors.isDark ? AppColors.warningSoftAlt : AppColors.warningSoft;
  static Color get errorLight =>
      activeColors.isDark ? AppColors.errorSoftAlt : AppColors.errorSoft;
  static Color get infoLight =>
      activeColors.isDark ? AppColors.infoSoftAlt : AppColors.infoSoft;

  static const AppThemeColors lightColors = AppThemeColors(
    isDark: false,
    background: Color(0xFFF5F7FB),
    backgroundSecondary: Color(0xFFEDF3F7),
    backgroundTertiary: Color(0xFFFDFEFE),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceInteractive: Color(0xFFF6FAFC),
    modalSurface: Color(0xFFFFFFFF),
    inputFill: Color(0xFFF7FBFD),
    navSurface: Color(0xFFFFFFFF),
    accent: Color(0xFF1098F7),
    accentSecondary: Color(0xFF1FC4A7),
    accentTertiary: Color(0xFF56D7C4),
    accentSoft: Color(0xFFE8F6FF),
    accentGlow: Color(0xFF8DE3D6),
    success: Color(0xFF18C964),
    warning: Color(0xFFFFB020),
    error: Color(0xFFEF4444),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    textInverse: Color(0xFFF8FAFC),
    borderSubtle: Color(0xFFDDE7F0),
    borderStrong: Color(0xFFC4D3DF),
    divider: Color(0xFFE6EDF4),
    shadow: Color(0xFF1E293B),
    hover: Color(0x140F172A),
  );

  static const AppThemeColors darkColors = AppThemeColors(
    isDark: true,
    background: Color(0xFF030712),
    backgroundSecondary: Color(0xFF07111F),
    backgroundTertiary: Color(0xFF0B1830),
    surface: Color(0xFF091223),
    surfaceElevated: Color(0xFF0F1B31),
    surfaceInteractive: Color(0xFF14233F),
    modalSurface: Color(0xFF08111F),
    inputFill: Color(0xFF0E1930),
    navSurface: Color(0xFF060E1B),
    accent: Color(0xFF00D1FF),
    accentSecondary: Color(0xFF6EF2C0),
    accentTertiary: Color(0xFFFF7A18),
    accentSoft: Color(0xFF11344B),
    accentGlow: Color(0xFF2BD6FF),
    success: Color(0xFF2CD97E),
    warning: Color(0xFFFFB54A),
    error: Color(0xFFFF5B6E),
    textPrimary: Color(0xFFF4F7FF),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    textInverse: Color(0xFFF8FAFC),
    borderSubtle: Color(0xFF20314A),
    borderStrong: Color(0xFF355274),
    divider: Color(0xFF16253D),
    shadow: Color(0xFF020611),
    hover: Color(0x14F8FAFC),
  );

  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  static const double radiusXS = 4;
  static const double radiusS = 8;
  static const double radiusM = 10;
  static const double radiusL = 12;
  static const double radiusXL = 16;
  static const double radiusRound = 999;

  static AppThemeColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>() ?? lightColors;

  static TextStyle _heading1(AppThemeColors colors) => GoogleFonts.sora(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
        height: 1.1,
        letterSpacing: 0,
      );

  static TextStyle _heading2(AppThemeColors colors) => GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
        height: 1.18,
        letterSpacing: 0,
      );

  static TextStyle _heading3(AppThemeColors colors) => GoogleFonts.sora(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.25,
        letterSpacing: 0,
      );

  static TextStyle _heading4(AppThemeColors colors) => GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
        letterSpacing: 0,
      );

  static TextStyle _bodyLarge(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.5,
        letterSpacing: 0,
      );

  static TextStyle _bodyMedium(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
        height: 1.5,
        letterSpacing: 0,
      );

  static TextStyle _bodySmall(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textMuted,
        height: 1.45,
        letterSpacing: 0,
      );

  static TextStyle _labelLarge(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle _labelMedium(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle _labelSmall(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: colors.textMuted,
        letterSpacing: 0,
      );

  static TextStyle _buttonMedium(AppThemeColors colors) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: colors.textInverse,
        letterSpacing: 0,
      );

  static TextTheme _textTheme(AppThemeColors colors) => TextTheme(
        displayLarge: _heading1(colors).copyWith(fontSize: 54),
        displayMedium: _heading1(colors).copyWith(fontSize: 44),
        displaySmall: _heading1(colors).copyWith(fontSize: 36),
        headlineLarge: _heading1(colors),
        headlineMedium: _heading2(colors),
        headlineSmall: _heading3(colors),
        titleLarge: _heading4(colors),
        titleMedium: _labelLarge(colors),
        titleSmall: _labelMedium(colors),
        bodyLarge: _bodyLarge(colors),
        bodyMedium: _bodyMedium(colors),
        bodySmall: _bodySmall(colors),
        labelLarge: _labelLarge(colors),
        labelMedium: _labelMedium(colors),
        labelSmall: _labelSmall(colors),
      );

  // Legacy typography accessors retained for existing screens.
  static TextStyle get heading1 => _heading1(activeColors);
  static TextStyle get heading2 => _heading2(activeColors);
  static TextStyle get heading3 => _heading3(activeColors);
  static TextStyle get heading4 => _heading4(activeColors);
  static TextStyle get bodyLarge => _bodyLarge(activeColors);
  static TextStyle get bodyMedium => _bodyMedium(activeColors);
  static TextStyle get bodySmall => _bodySmall(activeColors);
  static TextStyle get labelLarge => _labelLarge(activeColors);
  static TextStyle get labelMedium => _labelMedium(activeColors);
  static TextStyle get labelSmall => _labelSmall(activeColors);
  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: activeColors.textInverse,
        letterSpacing: 0,
      );
  static TextStyle get buttonMedium => _buttonMedium(activeColors);
  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: activeColors.textInverse,
        letterSpacing: 0,
      );

  static List<BoxShadow> get shadowXS => [
        BoxShadow(
          color: activeColors.shadow
              .withValues(alpha: activeColors.isDark ? 0.18 : 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowS => activeColors.softShadow;
  static List<BoxShadow> get shadowM => activeColors.mediumShadow;
  static List<BoxShadow> get shadowL => [
        BoxShadow(
          color: activeColors.shadow
              .withValues(alpha: activeColors.isDark ? 0.26 : 0.16),
          blurRadius: activeColors.isDark ? 32 : 28,
          offset: const Offset(0, 14),
        ),
      ];
  static List<BoxShadow> get shadowXL => activeColors.glowShadow;

  static BoxDecoration cardDecoration({
    BuildContext? context,
    Color? color,
    double? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    final colors = context != null ? colorsOf(context) : lightColors;
    return BoxDecoration(
      color: color ?? colors.surfaceElevated,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusM),
      border: Border.all(color: colors.borderSubtle, width: 1),
      boxShadow: shadows ?? colors.softShadow,
    );
  }

  static ButtonStyle primaryButtonStyle({
    BuildContext? context,
    double? padding,
    double? borderRadius,
  }) {
    final colors = context != null ? colorsOf(context) : lightColors;
    return _primaryButtonStyleForColors(
      colors,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  static ButtonStyle _primaryButtonStyleForColors(
    AppThemeColors colors, {
    double? padding,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: colors.accent,
      foregroundColor: colors.textInverse,
      disabledBackgroundColor: colors.borderSubtle,
      disabledForegroundColor: colors.textMuted,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: padding ?? spacingL,
        vertical: padding != null ? padding * 0.65 : spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusS),
      ),
      textStyle: _buttonMedium(colors),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return colors.textInverse.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }

  static ButtonStyle secondaryButtonStyle({
    BuildContext? context,
    double? padding,
    double? borderRadius,
  }) {
    final colors = context != null ? colorsOf(context) : lightColors;
    return _secondaryButtonStyleForColors(
      colors,
      padding: padding,
      borderRadius: borderRadius,
    );
  }

  static ButtonStyle _secondaryButtonStyleForColors(
    AppThemeColors colors, {
    double? padding,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.accent,
      side: BorderSide(color: colors.borderStrong, width: 1.2),
      backgroundColor: colors.surfaceElevated,
      padding: EdgeInsets.symmetric(
        horizontal: padding ?? spacingL,
        vertical: padding != null ? padding * 0.65 : spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusS),
      ),
      textStyle: _buttonMedium(colors).copyWith(color: colors.accent),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return colors.hover;
        }
        return null;
      }),
    );
  }

  static ButtonStyle textButtonStyle({BuildContext? context}) {
    final colors = context != null ? colorsOf(context) : lightColors;
    return _textButtonStyleForColors(colors);
  }

  static ButtonStyle _textButtonStyleForColors(AppThemeColors colors) {
    return TextButton.styleFrom(
      foregroundColor: colors.accent,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
      textStyle: _buttonMedium(colors).copyWith(color: colors.accent),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return colors.hover;
        }
        return null;
      }),
    );
  }

  static InputDecoration inputDecoration({
    BuildContext? context,
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final colors = context != null ? colorsOf(context) : lightColors;
    return _inputDecorationForColors(
      colors,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  static InputDecoration _inputDecorationForColors(
    AppThemeColors colors, {
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.inputFill,
      labelStyle: _labelMedium(colors).copyWith(color: colors.textSecondary),
      hintStyle: _bodyMedium(colors).copyWith(color: colors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.error, width: 1.8),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationThemeForColors(
    AppThemeColors colors,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      labelStyle: _labelMedium(colors).copyWith(color: colors.textSecondary),
      hintStyle: _bodyMedium(colors).copyWith(color: colors.textMuted),
      prefixIconColor: colors.textSecondary,
      suffixIconColor: colors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusS),
        borderSide: BorderSide(color: colors.error, width: 1.8),
      ),
    );
  }

  static ThemeData _buildTheme(AppThemeColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: colors.isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: colors.accent,
      onPrimary: colors.textInverse,
      primaryContainer: colors.accentSoft,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.accentSecondary,
      onSecondary: colors.textInverse,
      secondaryContainer: colors.surfaceInteractive,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.accentTertiary,
      onTertiary: colors.textInverse,
      error: colors.error,
      onError: colors.textInverse,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceInteractive,
      outline: colors.borderStrong,
      outlineVariant: colors.borderSubtle,
      shadow: colors.shadow,
    );

    final textTheme = _textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: colors.isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[],
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colors.navSurface,
        foregroundColor: colors.textPrimary,
        systemOverlayStyle: colors.isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.navSurface,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.navSurface,
              ),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _heading3(colors),
        iconTheme: IconThemeData(color: colors.textPrimary, size: 24),
        toolbarHeight: 72,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceElevated,
        shadowColor:
            colors.shadow.withValues(alpha: colors.isDark ? 0.36 : 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyleForColors(colors),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.textInverse,
          disabledBackgroundColor: colors.borderSubtle,
          disabledForegroundColor: colors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: _buttonMedium(colors),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _secondaryButtonStyleForColors(colors),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyleForColors(colors),
      ),
      inputDecorationTheme: _inputDecorationThemeForColors(colors),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.navSurface,
        indicatorColor: colors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return _labelSmall(colors).copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.navSurface,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textMuted,
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.modalSurface,
        contentTextStyle:
            _bodyMedium(colors).copyWith(color: colors.textPrimary),
        actionTextColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: _heading3(colors),
        contentTextStyle: _bodyMedium(colors),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: colors.borderSubtle),
        ),
        textStyle: _bodyMedium(colors).copyWith(color: colors.textPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceInteractive,
        selectedColor: colors.accentSoft,
        disabledColor: colors.borderSubtle,
        labelStyle: _labelMedium(colors),
        side: BorderSide(color: colors.borderSubtle),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingM, vertical: spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusRound),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceInteractive,
        circularTrackColor: colors.surfaceInteractive,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.modalSurface,
          borderRadius: BorderRadius.circular(radiusS),
          border: Border.all(color: colors.borderSubtle),
        ),
        textStyle: _bodySmall(colors).copyWith(color: colors.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent.withValues(alpha: 0.45);
          }
          return colors.borderStrong;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.surface;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.surfaceInteractive;
        }),
        checkColor: WidgetStatePropertyAll(colors.textInverse),
        side: BorderSide(color: colors.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXS),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        splashColor: colors.textInverse.withValues(alpha: 0.12),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: _bodyMedium(colors).copyWith(color: colors.textPrimary),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.modalSurface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: colors.borderSubtle)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.modalSurface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: colors.borderSubtle)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: 0.22),
        selectionHandleColor: colors.accent,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(colors.inputFill),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(colors.shadow),
        side: WidgetStatePropertyAll(BorderSide(color: colors.borderSubtle)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          _bodyMedium(colors).copyWith(color: colors.textPrimary),
        ),
        hintStyle: WidgetStatePropertyAll(
          _bodyMedium(colors).copyWith(color: colors.textMuted),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: colors.divider,
        indicatorColor: colors.accent,
        labelColor: colors.accent,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: _labelMedium(colors),
        unselectedLabelStyle: _labelMedium(colors).copyWith(
          color: colors.textSecondary,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: colors.surfaceElevated,
        collapsedBackgroundColor: colors.surfaceElevated,
        textColor: colors.textPrimary,
        collapsedTextColor: colors.textPrimary,
        iconColor: colors.textSecondary,
        collapsedIconColor: colors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: colors.borderSubtle),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(lightColors);
  static ThemeData get darkTheme => _buildTheme(darkColors);
}
