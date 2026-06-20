// packages/shared/lib/design/tokens.dart
//
// نظام التصميم المركزي — كل الألوان والمسافات والأبعاد هنا
// أي تعديل في التصميم يتم من هذا الملف فقط

import 'package:flutter/material.dart';

/// ألوان التطبيق الأساسية
///
/// 5 Accent Colors موثقة مع وصف كل منها
abstract class AppColors {
  // ── الألوان الرئيسية ─────────────────────────────────────

  /// الأخضر الرئيسي — مأخوذ من شعار TO Best
  static const primary = Color(0xFF3FAD1F);

  /// الأخضر الداكن
  static const primaryDark = Color(0xFF2D8415);

  /// الأخضر الفاتح
  static const primaryLight = Color(0xFF5DC43A);

  // ── 5 Accent Colors ──────────────────────────────────────

  /// Slate Indigo — تقنية، محايدة، عصرية
  static const accent1 = Color(0xFF4F46E5);

  /// Deep Teal — هادئة، طبيعية، احترافية
  static const accent2 = Color(0xFF0F766E);

  /// Warm Amber — دافئة، مرحّبة، واضحة
  static const accent3 = Color(0xFFD97706);

  /// Dusty Rose — عصرية، ناعمة، غير صارخة
  static const accent4 = Color(0xFFE11D48);

  /// Slate Gray — محايدة، مهنية، كلاسيكية
  static const accent5 = Color(0xFF475569);

  // ── ألوان الحالات ────────────────────────────────────────
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFCA8A04);
  static const error   = Color(0xFFDC2626);
  static const info    = Color(0xFF0284C7);

  // ── ألوان الخلفيات (Light) ───────────────────────────────
  static const backgroundLight     = Color(0xFFF9FAFB);
  static const surfaceLight        = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF3F4F6);

  // ── ألوان الخلفيات (Dark) ───────────────────────────────
  static const backgroundDark     = Color(0xFF111827);
  static const surfaceDark        = Color(0xFF1F2937);
  static const surfaceVariantDark = Color(0xFF374151);

  // ── ألوان النصوص (Light) ────────────────────────────────
  static const textPrimaryLight   = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textDisabledLight  = Color(0xFF9CA3AF);

  // ── ألوان النصوص (Dark) ─────────────────────────────────
  static const textPrimaryDark   = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const textDisabledDark  = Color(0xFF6B7280);

  // ── ألوان Streak / Heatmap ───────────────────────────────
  static const heatmapEmpty  = Color(0xFFE5E7EB);
  static const heatmapLight  = Color(0xFFBBF7D0);
  static const heatmapMedium = Color(0xFF4ADE80);
  static const heatmapDark   = Color(0xFF16A34A);

  // ── ألوان الشات ──────────────────────────────────────────
  static const chatBubbleSelf  = Color(0xFF3FAD1F);
  static const chatBubbleOther = Color(0xFFF3F4F6);

  // ── ألوان الثيم الأزرق ──────────────────────────────────
  static const blueThemePrimary    = Color(0xFF1E3A8A);
  static const blueThemeBackground = Color(0xFF0F172A);
  static const blueThemeSurface    = Color(0xFF1E293B);

  // ── ألوان الثيم الوردي ──────────────────────────────────
  static const pinkThemePrimary    = Color(0xFFDB2777);
  static const pinkThemeBackground = Color(0xFFFFF1F2);
  static const pinkThemeSurface    = Color(0xFFFFFFFF);
}

/// قيم المسافات والأبعاد — نظام 4px
abstract class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 48;

  // ── Border Radius ────────────────────────────────────────
  /// الافتراضي للبطاقات والأزرار
  static const double radiusMd  = 12;
  static const double radiusLg  = 16;
  static const double radiusFull = 999;

  // ── أحجام الأيقونات ──────────────────────────────────────
  static const double iconSm  = 16;
  static const double iconMd  = 20;
  static const double iconLg  = 24;
  static const double iconXl  = 32;
  static const double iconXxl = 48;
}

/// إعدادات الخطوط
abstract class AppTypography {
  /// الخط العربي
  static const String fontAr = 'Cairo';

  /// الخط الإنجليزي
  static const String fontEn = 'Inter';

  // ── أحجام الخطوط ─────────────────────────────────────────
  static const double labelSm  = 11;
  static const double labelMd  = 12;
  static const double bodySm   = 13;
  static const double bodyMd   = 14;
  static const double bodyLg   = 16;
  static const double titleSm  = 18;
  static const double titleMd  = 20;
  static const double titleLg  = 24;
  static const double displaySm = 28;
  static const double displayMd = 32;
  static const double displayLg = 40;
}

/// مدد الـ Animations — هادئة ومحسوبة
abstract class AppDurations {
  static const fast   = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow   = Duration(milliseconds: 350);
  static const breath = Duration(seconds: 4);  // Breathing animation
}

/// ظلال البطاقات
abstract class AppShadows {
  static final sm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final md = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final lg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
