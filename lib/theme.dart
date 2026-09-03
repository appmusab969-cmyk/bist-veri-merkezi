import 'package:flutter/material.dart';

/// Ham tasarım token'ları (FireVibe.ai export'undan).
class AppColors {
  static const background = Color(0xFF0D1117);
  static const foreground = Color(0xFFF2F7F5);
  static const primary = Color(0xFF00E676);
  static const primaryForeground = Color(0xFF06140D);
  static const secondary = Color(0xFF1B222C);
  static const secondaryForeground = Color(0xFFD9E7E3);
  static const accent = Color(0xFFFF9100);
  static const accentForeground = Color(0xFF201000);
  static const muted = Color(0xFF212936);
  static const mutedForeground = Color(0xFF9AA6B2);
  static const card = Color(0xFF161B22);
  static const cardForeground = Color(0xFFF2F7F5);
  static const border = Color(0xFF303944);
  static const input = Color(0xFF1C232D);
  static const destructive = Color(0xFFFF5252);
  static const destructiveForeground = Color(0xFFFFF7F6);
  static const success = Color(0xFF00E676);
  static const successForeground = Color(0xFF06140D);
  static const chart1 = Color(0xFF19B77A);
  static const chart2 = Color(0xFFD6A84A);
  static const chart3 = Color(0xFF4FA3D1);
  static const chart4 = Color(0xFFA98BD4);
  static const chart5 = Color(0xFFDE7E62);
}

class AppFonts {
  static const heading = 'Manrope';
  static const body = 'Inter';
}

class AppTheme {
  static const cornerRadius = 12.0;
  static final borderRadius = BorderRadius.circular(12.0);

  /// Ekranlar `Theme.of(context).colorScheme` üzerinden çalıştığı için
  /// AppColors token'larını eksiksiz bir [ColorScheme]'e eşliyoruz.
  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.primaryForeground,
      secondary: AppColors.secondaryForeground,
      onSecondary: AppColors.foreground,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.secondaryForeground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.accentForeground,
      tertiaryContainer: AppColors.accent,
      onTertiaryContainer: AppColors.accentForeground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      errorContainer: AppColors.destructive,
      onErrorContainer: AppColors.destructiveForeground,
      surface: AppColors.background,
      onSurface: AppColors.foreground,
      onSurfaceVariant: AppColors.mutedForeground,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.card,
      surfaceContainer: AppColors.card,
      surfaceContainerHigh: AppColors.input,
      surfaceContainerHighest: AppColors.muted,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.foreground,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: AppFonts.body,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      dividerColor: scheme.outline,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary.withValues(alpha: .12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
