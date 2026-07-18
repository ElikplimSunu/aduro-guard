import 'package:flutter/material.dart';

/// Design tokens for Aduro Guard — the single source of truth.
/// Direction: Ghana gold + warm charcoal. Rules: see DESIGN.md.
/// Every color/size/space in the app traces back to a constant here.
abstract final class T {
  // ── Brand ramp: ochre gold ────────────────────────────────────────────
  static const brand50 = Color(0xFFFBF6EB);
  static const brand100 = Color(0xFFF6ECD3);
  static const brand200 = Color(0xFFEDDBAA);
  static const brand300 = Color(0xFFE2C67D);
  static const brand400 = Color(0xFFD4AC4E);
  static const brand500 = Color(0xFFC29435);
  static const brand600 = Color(0xFFB07818); // anchor; ≥3:1 on neutral0 (large/UI only)
  static const brand700 = Color(0xFF8F6113); // primary action bg; 5.1:1 with neutral0 text
  static const brand800 = Color(0xFF6F4B10);
  static const brand900 = Color(0xFF52370D);
  static const brand950 = Color(0xFF33220A);

  // ── Warm neutrals (gold-biased, never pure) ───────────────────────────
  static const neutral0 = Color(0xFFFBF9F4); // card/surface paper
  static const neutral50 = Color(0xFFF5F2EA); // app background
  static const neutral100 = Color(0xFFEDE9DE);
  static const neutral200 = Color(0xFFDFD9CB);
  static const neutral300 = Color(0xFFC9C2B2);
  static const neutral400 = Color(0xFFA8A091);
  static const neutral500 = Color(0xFF857E70); // placeholders/disabled only (3.8:1)
  static const neutral600 = Color(0xFF6A6357); // secondary text (5.5:1 on neutral0)
  static const neutral700 = Color(0xFF524C42);
  static const neutral800 = Color(0xFF3A362E);
  static const neutral900 = Color(0xFF23201A); // primary ink
  static const neutral950 = Color(0xFF171511);

  // ── Semantic (desaturated, warm-adjacent; reserved for verdicts) ──────
  static const success600 = Color(0xFF3E7D4E);
  static const success700 = Color(0xFF2F6340); // small text on successSurface
  static const successSurface = Color(0xFFE7F0E8);
  static const warning600 = Color(0xFFB4571D); // burnt amber — distinct from brand gold
  static const warning700 = Color(0xFF93461A);
  static const warningSurface = Color(0xFFF8E9DD);
  static const danger600 = Color(0xFFB5443A);
  static const danger700 = Color(0xFF94362E);
  static const dangerSurface = Color(0xFFF6E3E0);

  // ── Type families ─────────────────────────────────────────────────────
  static const fontDisplay = 'Fraunces';
  static const fontBody = 'Public Sans';
  static const fontData = 'IBM Plex Mono';

  // ── Type scale (complete ladder — no orphan sizes) ────────────────────
  static const display = TextStyle(
      fontFamily: fontDisplay, fontSize: 32, height: 38 / 32,
      fontWeight: FontWeight.w600, letterSpacing: -0.5, color: neutral900);
  static const h1 = TextStyle(
      fontFamily: fontDisplay, fontSize: 24, height: 30 / 24,
      fontWeight: FontWeight.w600, letterSpacing: -0.3, color: neutral900);
  static const h2 = TextStyle(
      fontFamily: fontDisplay, fontSize: 20, height: 26 / 20,
      fontWeight: FontWeight.w600, color: neutral900);
  static const h3 = TextStyle(
      fontFamily: fontBody, fontSize: 17, height: 24 / 17,
      fontWeight: FontWeight.w600, color: neutral900);
  static const body = TextStyle(
      fontFamily: fontBody, fontSize: 15, height: 22 / 15,
      fontWeight: FontWeight.w400, color: neutral900);
  static const bodyStrong = TextStyle(
      fontFamily: fontBody, fontSize: 15, height: 22 / 15,
      fontWeight: FontWeight.w600, color: neutral900);
  static const small = TextStyle(
      fontFamily: fontBody, fontSize: 13, height: 18 / 13,
      fontWeight: FontWeight.w400, color: neutral600);
  static const caption = TextStyle(
      fontFamily: fontBody, fontSize: 11.5, height: 16 / 11.5,
      fontWeight: FontWeight.w500, letterSpacing: 0.2, color: neutral600);
  // Data face: batch numbers, reg numbers, dates. Tabular by design (mono).
  static const data = TextStyle(
      fontFamily: fontData, fontSize: 13, height: 18 / 13,
      fontWeight: FontWeight.w400, color: neutral900);
  static const dataLarge = TextStyle(
      fontFamily: fontData, fontSize: 15, height: 22 / 15,
      fontWeight: FontWeight.w500, color: neutral900);

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

  // ── Radius system (one scale, applied everywhere) ─────────────────────
  static const rSm = 8.0; // chips, tags, small fields
  static const rMd = 12.0; // buttons, cards, inputs
  static const rLg = 20.0; // sheets, hero surfaces, verdict banner
}
