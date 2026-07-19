import 'package:flutter/material.dart';
import 'tokens.dart';

/// App themes built exclusively from tokens + the [AduroColors] roles.
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AduroColors.dark : AduroColors.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.brandPrimary,
    onPrimary: c.onBrandPrimary,
    secondary: c.brandAccent,
    onSecondary: c.onBrandPrimary,
    error: c.dangerAccent,
    onError: c.surface,
    surface: c.surface,
    onSurface: c.ink,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.bg,
    surfaceContainer: c.bg,
    surfaceContainerHigh: c.surfaceDim,
    surfaceContainerHighest: c.surfaceDim,
    outline: c.hairlineStrong,
    outlineVariant: c.hairline,
    onSurfaceVariant: c.inkMuted,
    inverseSurface: c.ink,
    onInverseSurface: c.bg,
    shadow: T.neutral950,
    scrim: T.neutral950,
  );

  final radiusMd = BorderRadius.circular(T.rMd);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: T.fontBody,
    splashFactory: InkSparkle.splashFactory,
    extensions: [c],
    textTheme: TextTheme(
      displaySmall: T.display.copyWith(color: c.ink),
      headlineMedium: T.h1.copyWith(color: c.ink),
      headlineSmall: T.h2.copyWith(color: c.ink),
      titleMedium: T.h3.copyWith(color: c.ink),
      bodyMedium: T.body.copyWith(color: c.ink),
      bodySmall: T.small.copyWith(color: c.inkMuted),
      labelLarge: T.bodyStrong.copyWith(color: c.ink),
      labelSmall: T.caption.copyWith(color: c.inkMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.ink,
      titleTextStyle: T.h3.copyWith(color: c.ink),
      iconTheme: IconThemeData(color: c.inkMuted, size: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.surfaceDim;
          if (states.contains(WidgetState.pressed)) {
            return brightness == Brightness.dark ? T.brand600 : T.brand800;
          }
          return c.brandPrimary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? c.inkFaint
                : c.onBrandPrimary),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(T.bodyStrong),
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: T.s6)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled) ? c.inkFaint : c.ink),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
            color: states.contains(WidgetState.focused)
                ? c.brandAccent
                : c.hairlineStrong)),
        textStyle: const WidgetStatePropertyAll(T.bodyStrong),
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: T.s6)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
            brightness == Brightness.dark ? c.brandAccent : c.brandPrimary),
        textStyle: const WidgetStatePropertyAll(T.bodyStrong),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: T.body.copyWith(color: c.inkFaint),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: T.s4, vertical: T.s3),
      border: OutlineInputBorder(
          borderRadius: radiusMd, borderSide: BorderSide(color: c.hairline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd, borderSide: BorderSide(color: c.hairline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.brandAccent, width: 1.5)),
    ),
    dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.inkMuted,
      titleTextStyle: T.bodyStrong.copyWith(color: c.ink),
      subtitleTextStyle: T.small.copyWith(color: c.inkMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: T.body.copyWith(color: c.bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.brandAccent,
      linearTrackColor: c.surfaceDim,
      circularTrackColor: c.surfaceDim,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
    ),
  );
}
