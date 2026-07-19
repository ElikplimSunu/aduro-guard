import 'package:flutter/material.dart';

/// Design tokens for Aduro Guard. Direction: Ghana gold + warm charcoal.
/// Rules: see DESIGN.md. Raw ramps, type scale, spacing and radii live here;
/// theme-dependent COLOR ROLES live in [AduroColors] below.
abstract final class T {
  // ── Brand ramp: ochre gold (brightness-independent) ───────────────────
  static const brand50 = Color(0xFFFBF6EB);
  static const brand100 = Color(0xFFF6ECD3);
  static const brand200 = Color(0xFFEDDBAA);
  static const brand300 = Color(0xFFE2C67D);
  static const brand400 = Color(0xFFD4AC4E);
  static const brand500 = Color(0xFFC29435);
  static const brand600 = Color(0xFFB07818); // anchor
  static const brand700 = Color(0xFF8F6113);
  static const brand800 = Color(0xFF6F4B10);
  static const brand900 = Color(0xFF52370D);
  static const brand950 = Color(0xFF33220A);

  // ── Warm neutrals (gold-biased, never pure) ───────────────────────────
  static const neutral0 = Color(0xFFFBF9F4);
  static const neutral50 = Color(0xFFF5F2EA);
  static const neutral100 = Color(0xFFEDE9DE);
  static const neutral200 = Color(0xFFDFD9CB);
  static const neutral300 = Color(0xFFC9C2B2);
  static const neutral400 = Color(0xFFA8A091);
  static const neutral500 = Color(0xFF857E70);
  static const neutral600 = Color(0xFF6A6357);
  static const neutral700 = Color(0xFF524C42);
  static const neutral800 = Color(0xFF3A362E);
  static const neutral900 = Color(0xFF23201A);
  static const neutral950 = Color(0xFF171511);

  // ── Type families ─────────────────────────────────────────────────────
  static const fontDisplay = 'Fraunces';
  static const fontBody = 'Public Sans';
  static const fontData = 'IBM Plex Mono';

  // ── Type scale (complete ladder, colorless: color comes from the theme
  //    or an explicit copyWith at the call site) ─────────────────────────
  static const display = TextStyle(
      fontFamily: fontDisplay, fontSize: 32, height: 38 / 32,
      fontWeight: FontWeight.w600, letterSpacing: -0.5);
  static const h1 = TextStyle(
      fontFamily: fontDisplay, fontSize: 24, height: 30 / 24,
      fontWeight: FontWeight.w600, letterSpacing: -0.3);
  static const h2 = TextStyle(
      fontFamily: fontDisplay, fontSize: 20, height: 26 / 20,
      fontWeight: FontWeight.w600);
  static const h3 = TextStyle(
      fontFamily: fontBody, fontSize: 17, height: 24 / 17,
      fontWeight: FontWeight.w600);
  static const body = TextStyle(
      fontFamily: fontBody, fontSize: 15, height: 22 / 15,
      fontWeight: FontWeight.w400);
  static const bodyStrong = TextStyle(
      fontFamily: fontBody, fontSize: 15, height: 22 / 15,
      fontWeight: FontWeight.w600);
  static const small = TextStyle(
      fontFamily: fontBody, fontSize: 13, height: 18 / 13,
      fontWeight: FontWeight.w400);
  static const caption = TextStyle(
      fontFamily: fontBody, fontSize: 11.5, height: 16 / 11.5,
      fontWeight: FontWeight.w500, letterSpacing: 0.2);
  static const data = TextStyle(
      fontFamily: fontData, fontSize: 13, height: 18 / 13,
      fontWeight: FontWeight.w400);
  static const dataLarge = TextStyle(
      fontFamily: fontData, fontSize: 15, height: 22 / 15,
      fontWeight: FontWeight.w500);

  // ── Spacing scale (4-base, no orphans) ────────────────────────────────
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;

  // ── Radius system ─────────────────────────────────────────────────────
  static const rSm = 8.0;
  static const rMd = 12.0;
  static const rLg = 20.0;
}

/// Color ROLES, themed. Light and dark are both warm (DESIGN.md: tinted
/// neutrals, never pure black or white; gold reserved for the primary
/// action; verdict colors reserved for verdicts).
@immutable
class AduroColors extends ThemeExtension<AduroColors> {
  final Color bg; // scaffold
  final Color surface; // cards
  final Color surfaceDim; // quiet fills (thumb placeholders, mute banner)
  final Color hairline; // card borders, dividers
  final Color hairlineStrong; // outlined-button borders, unselected chips
  final Color ink; // headings + body
  final Color inkMuted; // secondary text
  final Color inkFaint; // placeholders, disabled, empty values
  final Color brandPrimary; // the one gold action surface
  final Color onBrandPrimary;
  final Color brandAccent; // links, focus, progress, small gold moments
  final Color successAccent, successText, successSurface;
  final Color warningAccent, warningText, warningSurface;
  final Color dangerAccent, dangerText, dangerSurface;
  final Color muteAccent, muteText, muteSurface;

  const AduroColors({
    required this.bg,
    required this.surface,
    required this.surfaceDim,
    required this.hairline,
    required this.hairlineStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.brandPrimary,
    required this.onBrandPrimary,
    required this.brandAccent,
    required this.successAccent,
    required this.successText,
    required this.successSurface,
    required this.warningAccent,
    required this.warningText,
    required this.warningSurface,
    required this.dangerAccent,
    required this.dangerText,
    required this.dangerSurface,
    required this.muteAccent,
    required this.muteText,
    required this.muteSurface,
  });

  static const light = AduroColors(
    bg: T.neutral50,
    surface: T.neutral0,
    surfaceDim: T.neutral100,
    hairline: T.neutral200,
    hairlineStrong: T.neutral300,
    ink: T.neutral900,
    inkMuted: T.neutral600,
    inkFaint: T.neutral500,
    brandPrimary: T.brand700, // 5.1:1 with ivory text
    onBrandPrimary: T.neutral0,
    brandAccent: T.brand600,
    successAccent: Color(0xFF3E7D4E),
    successText: Color(0xFF2F6340),
    successSurface: Color(0xFFE7F0E8),
    warningAccent: Color(0xFFB4571D),
    warningText: Color(0xFF93461A),
    warningSurface: Color(0xFFF8E9DD),
    dangerAccent: Color(0xFFB5443A),
    dangerText: Color(0xFF94362E),
    dangerSurface: Color(0xFFF6E3E0),
    muteAccent: T.neutral500,
    muteText: T.neutral700,
    muteSurface: T.neutral100,
  );

  static const dark = AduroColors(
    bg: T.neutral950,
    surface: T.neutral900,
    surfaceDim: Color(0xFF2C2822),
    hairline: T.neutral800,
    hairlineStrong: T.neutral700,
    ink: T.neutral50,
    inkMuted: T.neutral400,
    inkFaint: T.neutral500,
    brandPrimary: T.brand500, // 6.1:1 with near-black text
    onBrandPrimary: T.neutral950,
    brandAccent: T.brand400,
    successAccent: Color(0xFF5FA96F),
    successText: Color(0xFFA6D2AF),
    successSurface: Color(0xFF1C2B1F),
    warningAccent: Color(0xFFCE7A3D),
    warningText: Color(0xFFE2B189),
    warningSurface: Color(0xFF33231A),
    dangerAccent: Color(0xFFCF6A5E),
    dangerText: Color(0xFFE5A79E),
    dangerSurface: Color(0xFF331E1B),
    muteAccent: T.neutral500,
    muteText: T.neutral300,
    muteSurface: Color(0xFF2C2822),
  );

  @override
  AduroColors copyWith() => this; // fields only ever swap wholesale

  @override
  AduroColors lerp(AduroColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AduroColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceDim: l(surfaceDim, other.surfaceDim),
      hairline: l(hairline, other.hairline),
      hairlineStrong: l(hairlineStrong, other.hairlineStrong),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkFaint: l(inkFaint, other.inkFaint),
      brandPrimary: l(brandPrimary, other.brandPrimary),
      onBrandPrimary: l(onBrandPrimary, other.onBrandPrimary),
      brandAccent: l(brandAccent, other.brandAccent),
      successAccent: l(successAccent, other.successAccent),
      successText: l(successText, other.successText),
      successSurface: l(successSurface, other.successSurface),
      warningAccent: l(warningAccent, other.warningAccent),
      warningText: l(warningText, other.warningText),
      warningSurface: l(warningSurface, other.warningSurface),
      dangerAccent: l(dangerAccent, other.dangerAccent),
      dangerText: l(dangerText, other.dangerText),
      dangerSurface: l(dangerSurface, other.dangerSurface),
      muteAccent: l(muteAccent, other.muteAccent),
      muteText: l(muteText, other.muteText),
      muteSurface: l(muteSurface, other.muteSurface),
    );
  }
}

extension AduroColorsX on BuildContext {
  /// The active palette: `context.c.ink`, `context.c.successAccent`, …
  AduroColors get c => Theme.of(this).extension<AduroColors>()!;
}
