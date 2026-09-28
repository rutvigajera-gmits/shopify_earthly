import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary  = Color(0xFF000D0F);
  static const Color teal     = Color(0xFF01414B);
  static const Color peach    = Color(0xFFFFDDBF);
  static const Color orange   = Color(0xFFED8C51);

  // ── Surface ────────────────────────────────────────────────────────────────
  static const Color surfaceBase   = Color(0xFFFFFFFF);
  static const Color surfaceWarm   = Color(0xFFFDF8F5);
  static const Color surfaceSubtle = Color(0xFFFAFAFA);
  static const Color surfaceCream  = Color(0xFFFFF1E4);
  static const Color surfaceDark   = Color(0xFF171717);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF000D0F);
  static const Color textSecondary = Color(0xFF344054);
  static const Color textMuted     = Color(0xFF737373);
  static const Color textOnDark    = Color(0xFFFFDDBF);
  static const Color textWhite     = Color(0xFFFFFFFF);

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF0F7C64);
  static const Color sale    = Color(0xFF79D18A);
  static const Color rating  = Color(0xFFF59E0B);
  static const Color badge   = Color(0xFFEB1256);
  static const Color error   = Color(0xFFD32F2F);
  static const Color focus   = Color(0xFF0B61CD);

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const Color neutral900 = Color(0xFF212B36);
  static const Color neutral700 = Color(0xFF344054);
  static const Color neutral500 = Color(0xFF868686);
  static const Color neutral300 = Color(0xFFD0D5DD);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral000 = Color(0xFFFFFFFF);

  // ── Semantic aliases (used throughout app) ─────────────────────────────────
  static const Color background        = surfaceBase;
  static const Color surface           = surfaceWarm;
  static const Color cardBackground   = neutral100;
  static const Color border            = neutral200;
  static const Color divider           = neutral200;

  // Gold → brand orange for accent consistency
  static const Color gold              = orange;
  static const Color goldDark          = Color(0xFFD4722A);
  static const Color goldLight         = peach;
  static const Color goldSurface       = surfaceCream;

  static const Color announcementBg    = primary;
  static const Color announcementText  = textWhite;

  // Shimmer
  static const Color shimmerBase       = Color(0xFFEEEBE6);
  static const Color shimmerHighlight  = Color(0xFFF8F5F0);

  // Legacy aliases kept for widgets not yet updated
  static const Color textLight         = textMuted;
  static const Color shadow            = Color(0x1A000000);
  static const Color badgeBackground   = Color(0xFFFFF0F3);
}
