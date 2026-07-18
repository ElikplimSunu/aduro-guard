import 'package:flutter/material.dart';
import 'tokens.dart';

/// App theme built exclusively from tokens.dart. No colors or sizes are
/// defined here that don't trace to a token.
ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: T.brand700,
    onPrimary: T.neutral0,
    secondary: T.brand600,
    onSecondary: T.neutral0,
    error: T.danger600,
    onError: T.neutral0,
    surface: T.neutral0,
    onSurface: T.neutral900,
    surfaceContainerLowest: T.neutral0,
    surfaceContainerLow: T.neutral50,
    surfaceContainer: T.neutral50,
    surfaceContainerHigh: T.neutral100,
    surfaceContainerHighest: T.neutral100,
    outline: T.neutral300,
    outlineVariant: T.neutral200,
    onSurfaceVariant: T.neutral600,
    inverseSurface: T.neutral900,
    onInverseSurface: T.neutral0,
    shadow: T.neutral950,
    scrim: T.neutral950,
  );

  final radiusMd = BorderRadius.circular(T.rMd);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: T.neutral50,
    fontFamily: T.fontBody,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      displaySmall: T.display,
      headlineMedium: T.h1,
      headlineSmall: T.h2,
      titleMedium: T.h3,
      bodyMedium: T.body,
      bodySmall: T.small,
      labelLarge: T.bodyStrong,
      labelSmall: T.caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: T.neutral50,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: T.neutral900,
      titleTextStyle: T.h3,
      iconTheme: IconThemeData(color: T.neutral700, size: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return T.neutral200;
          if (states.contains(WidgetState.pressed)) return T.brand800;
          return T.brand700;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return T.neutral500;
          return T.neutral0;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(
            T.bodyStrong.copyWith(color: T.neutral0)),
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
            states.contains(WidgetState.disabled)
                ? T.neutral500
                : T.neutral900),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
            color: states.contains(WidgetState.focused)
                ? T.brand600
                : T.neutral300)),
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
        foregroundColor: const WidgetStatePropertyAll(T.brand700),
        textStyle: const WidgetStatePropertyAll(T.bodyStrong),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: T.neutral0,
      hintStyle: T.body.copyWith(color: T.neutral500),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: T.s4, vertical: T.s3),
      border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: T.neutral200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: T.neutral200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: T.brand600, width: 1.5)),
    ),
    dividerTheme: const DividerThemeData(
        color: T.neutral200, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: T.neutral600,
      titleTextStyle: T.bodyStrong,
      subtitleTextStyle: T.small,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: T.neutral900,
      contentTextStyle: T.body.copyWith(color: T.neutral0),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: T.brand600,
      linearTrackColor: T.neutral200,
      circularTrackColor: T.neutral200,
    ),
  );
}
