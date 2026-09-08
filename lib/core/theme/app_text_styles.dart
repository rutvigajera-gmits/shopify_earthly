import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display / Hero headings — Cormorant Garamond (luxury serif)
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
        height: 1.3,
      );

  static TextStyle get displaySmall => GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.3,
      );

  // Section headings
  static TextStyle get headlineLarge => GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.cormorantGaramond(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.cormorantGaramond(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Body — Jost (clean, modern sans-serif)
  static TextStyle get bodyLarge => GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.jost(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Labels / Captions
  static TextStyle get labelLarge => GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.jost(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get labelSmall => GoogleFonts.jost(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      );

  // Price
  static TextStyle get priceText => GoogleFonts.jost(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get priceLarge => GoogleFonts.jost(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get priceStrikethrough => GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
        decoration: TextDecoration.lineThrough,
      );

  // Button text
  static TextStyle get button => GoogleFonts.jost(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      );

  static TextStyle get buttonLarge => GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
      );

  // Nav / Tab
  static TextStyle get navLabel => GoogleFonts.jost(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  // Announcement bar
  static TextStyle get announcement => GoogleFonts.jost(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.announcementText,
        letterSpacing: 1.5,
      );

  // Badge
  static TextStyle get badge => GoogleFonts.jost(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppColors.badge,
        letterSpacing: 1.0,
      );

  // Product name on card
  static TextStyle get productName => GoogleFonts.cormorantGaramond(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );
}
