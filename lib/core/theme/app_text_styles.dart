import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Lazily cache the Google Fonts Jost family identifier so nb_utils calls
  // resolve to the correct font without repeated GoogleFonts lookups.
  static String? _jostFamily;
  static String get _jost => _jostFamily ??= GoogleFonts.jost().fontFamily!;

  // ── Display / Hero — Cormorant Garamond (luxury serif) ──────────────────
  // nb_utils doesn't cover custom serif fonts; Google Fonts used directly here.
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 36, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.5, height: 1.2,
      );
  static TextStyle get displayMedium => GoogleFonts.cormorantGaramond(
        fontSize: 28, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.3, height: 1.3,
      );
  static TextStyle get displaySmall => GoogleFonts.cormorantGaramond(
        fontSize: 22, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary, letterSpacing: 0.2, height: 1.3,
      );
  static TextStyle get headlineLarge => GoogleFonts.cormorantGaramond(
        fontSize: 26, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.3, height: 1.25,
      );
  static TextStyle get headlineMedium => GoogleFonts.cormorantGaramond(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.2, height: 1.3,
      );
  static TextStyle get headlineSmall => GoogleFonts.cormorantGaramond(
        fontSize: 18, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary, height: 1.3,
      );
  static TextStyle get productName => GoogleFonts.cormorantGaramond(
        fontSize: 15, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary, height: 1.3,
      );

  // ── Body — Jost via nb_utils ─────────────────────────────────────────────
  // appTextPrimaryColor / appTextSecondaryColor are bound to AppColors in main.dart,
  // so omitting 'color' still uses brand tokens automatically.
  static TextStyle get bodyLarge =>
      primaryTextStyle(size: 16, fontFamily: _jost, height: 1.5);
  static TextStyle get bodyMedium =>
      primaryTextStyle(size: 14, fontFamily: _jost, height: 1.5);
  static TextStyle get bodySmall =>
      secondaryTextStyle(size: 12, fontFamily: _jost, height: 1.5);

  // ── Labels ────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => primaryTextStyle(
        size: 14, fontFamily: _jost,
        weight: FontWeight.w500, letterSpacing: 0.5,
      );
  static TextStyle get labelMedium => secondaryTextStyle(
        size: 12, fontFamily: _jost, letterSpacing: 0.8,
      );
  static TextStyle get labelSmall => secondaryTextStyle(
        size: 10, fontFamily: _jost, letterSpacing: 1.0,
      );

  // ── Price ─────────────────────────────────────────────────────────────────
  static TextStyle get priceText => primaryTextStyle(
        size: 15, fontFamily: _jost,
        weight: FontWeight.w600, letterSpacing: 0.3,
      );
  static TextStyle get priceLarge => boldTextStyle(
        size: 20, fontFamily: _jost, letterSpacing: 0.3,
      );
  static TextStyle get priceStrikethrough => secondaryTextStyle(
        size: 14, fontFamily: _jost, color: AppColors.textLight,
        decoration: TextDecoration.lineThrough,
      );

  // ── Button text ───────────────────────────────────────────────────────────
  static TextStyle get button => primaryTextStyle(
        size: 13, fontFamily: _jost,
        weight: FontWeight.w500, letterSpacing: 1.5,
      );
  static TextStyle get buttonLarge => primaryTextStyle(
        size: 14, fontFamily: _jost,
        weight: FontWeight.w500, letterSpacing: 2.0,
      );

  // ── Nav / Tab ─────────────────────────────────────────────────────────────
  static TextStyle get navLabel => primaryTextStyle(
        size: 10, fontFamily: _jost,
        weight: FontWeight.w500, letterSpacing: 0.5,
      );

  // ── Announcement bar ──────────────────────────────────────────────────────
  static TextStyle get announcement => primaryTextStyle(
        size: 11, fontFamily: _jost, color: AppColors.announcementText,
        weight: FontWeight.w500, letterSpacing: 1.5,
      );

  // ── Badge ─────────────────────────────────────────────────────────────────
  static TextStyle get badge => boldTextStyle(
        size: 9, fontFamily: _jost, color: AppColors.badge, letterSpacing: 1.0,
      );
}
