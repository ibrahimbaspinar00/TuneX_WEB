import 'package:flutter/material.dart';

import '../theme/app_design_system.dart';

class ProfessionalComponents {
  static PreferredSizeWidget createAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double elevation = 0,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      actions: actions,
      leading: leading,
    );
  }

  static Widget createCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double elevation = 2,
    BorderRadius? borderRadius,
    BoxShadow? shadow,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appTheme;
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: color ?? colors.surfaceElevated,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: shadow != null ? [shadow] : colors.softShadow,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );
      },
    );
  }

  static Widget createButton({
    required String text,
    required VoidCallback? onPressed,
    ButtonType type = ButtonType.primary,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appTheme;
        final config = _buttonColors(colors, type);
        final padding = _buttonPadding(size);
        final radius = _buttonRadius(size);

        final buttonChild = Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(config.foreground),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: size == ButtonSize.small ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

        if (type == ButtonType.outline) {
          return OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: config.foreground,
              backgroundColor: config.background,
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              side: BorderSide(color: config.border),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: buttonChild,
          );
        }

        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: config.background,
            foregroundColor: config.foreground,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            elevation: 0,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonChild,
        );
      },
    );
  }

  static Widget createInputField({
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
    bool enabled = true,
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              validator: validator,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLines: maxLines ?? 1,
              enabled: enabled,
              decoration: AppDesignSystem.inputDecoration(
                context: context,
                label: label,
                hint: hint,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
              ).copyWith(labelText: null),
            ),
          ],
        );
      },
    );
  }

  static Widget createLoadingIndicator({
    String? message,
    double size = 40,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appTheme;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? colors.accent,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Widget createEmptyState({
    required String title,
    required String message,
    IconData? icon,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appTheme;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 300),
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    decoration: AppDesignSystem.cardDecoration(
                      context: context,
                      shadows: colors.mediumShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 64,
                              color: colors.textMuted,
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (buttonText != null && onButtonPressed != null) ...[
                            const SizedBox(height: 32),
                            SizedBox(
                              width: 220,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: onButtonPressed,
                                child: Text(buttonText),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget createStatusBadge({
    required String text,
    StatusType type = StatusType.info,
    bool isSmall = false,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appTheme;
        final config = _statusConfig(colors, type);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 12,
            vertical: isSmall ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: config.background,
            borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
            border: Border.all(color: config.border),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: config.foreground,
            ),
          ),
        );
      },
    );
  }

  static Widget createDivider({
    String? text,
    double thickness = 1,
    Color? color,
    EdgeInsetsGeometry? margin,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appTheme;
        final dividerColor = color ?? colors.divider;
        if (text != null) {
          return Container(
            margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: thickness,
                    color: dividerColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: thickness,
                    color: dividerColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            thickness: thickness,
            color: dividerColor,
          ),
        );
      },
    );
  }

  static Widget createSectionHeader({
    required String title,
    String? subtitle,
    Widget? action,
    EdgeInsetsGeometry? padding,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          padding: padding ?? const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
        );
      },
    );
  }

  static _ButtonColors _buttonColors(AppThemeColors colors, ButtonType type) {
    switch (type) {
      case ButtonType.primary:
        return _ButtonColors(
          background: colors.accent,
          foreground: colors.textInverse,
          border: colors.accent,
        );
      case ButtonType.secondary:
        return _ButtonColors(
          background: colors.surfaceInteractive,
          foreground: colors.textPrimary,
          border: colors.borderSubtle,
        );
      case ButtonType.success:
        return _ButtonColors(
          background: colors.success,
          foreground: colors.textInverse,
          border: colors.success,
        );
      case ButtonType.danger:
        return _ButtonColors(
          background: colors.error,
          foreground: colors.textInverse,
          border: colors.error,
        );
      case ButtonType.outline:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: colors.accent,
          border: colors.borderStrong,
        );
    }
  }

  static _StatusColors _statusConfig(AppThemeColors colors, StatusType type) {
    switch (type) {
      case StatusType.success:
        return _StatusColors(
          background: colors.success.withValues(alpha: colors.isDark ? 0.18 : 0.12),
          foreground: colors.success,
          border: colors.success.withValues(alpha: 0.32),
        );
      case StatusType.warning:
        return _StatusColors(
          background: colors.warning.withValues(alpha: colors.isDark ? 0.18 : 0.12),
          foreground: colors.warning,
          border: colors.warning.withValues(alpha: 0.32),
        );
      case StatusType.error:
        return _StatusColors(
          background: colors.error.withValues(alpha: colors.isDark ? 0.18 : 0.12),
          foreground: colors.error,
          border: colors.error.withValues(alpha: 0.32),
        );
      case StatusType.info:
        return _StatusColors(
          background: colors.accent.withValues(alpha: colors.isDark ? 0.18 : 0.10),
          foreground: colors.accent,
          border: colors.accent.withValues(alpha: 0.28),
        );
    }
  }

  static EdgeInsetsGeometry _buttonPadding(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  static double _buttonRadius(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class _StatusColors {
  const _StatusColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

enum ButtonType { primary, secondary, success, danger, outline }

enum ButtonSize { small, medium, large }

enum StatusType { success, warning, error, info }
