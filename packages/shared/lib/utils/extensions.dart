// packages/shared/lib/utils/extensions.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extensions على DateTime
extension DateTimeExt on DateTime {
  /// تنسيق التاريخ العربي
  String toArabicDate() => DateFormat('d MMMM yyyy', 'ar').format(this);

  /// تنسيق التاريخ الإنجليزي
  String toEnglishDate() => DateFormat('MMMM d, yyyy').format(this);

  /// تنسيق الوقت (12h)
  String toTimeString({bool is24h = false}) =>
      is24h ? DateFormat('HH:mm').format(this) : DateFormat('h:mm a').format(this);

  /// هل في نفس اليوم
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// هل اليوم
  bool get isToday => isSameDay(DateTime.now());

  /// هل أمس
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// نص relative (اليوم، أمس، تاريخ)
  String toRelativeAr() {
    if (isToday)     return 'اليوم';
    if (isYesterday) return 'أمس';
    return toArabicDate();
  }

  /// بداية اليوم
  DateTime get startOfDay => DateTime(year, month, day);

  /// نهاية اليوم
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

/// Extensions على String
extension StringExt on String {
  /// هل إيميل صحيح
  bool get isValidEmail =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// هل رقم هاتف صحيح (مصري / سعودي / إماراتي)
  bool get isValidPhone =>
      RegExp(r'^(\+?\d{10,15})$').hasMatch(replaceAll(' ', ''));

  /// اختصار الاسم للأحرف الأولى (حتى حرفين)
  String get initials {
    final words = trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// هل النص عربي
  bool get isArabic => contains(RegExp(r'[\u0600-\u06FF]'));
}

/// Extensions على num
extension NumExt on num {
  /// تقريب لمنزلتين عشريتين
  double get roundTo2 => double.parse(toStringAsFixed(2));

  /// تحويل لكيلو بإضافة K
  String toCompactString() {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toString();
  }
}

/// Extensions على BuildContext
extension ContextExt on BuildContext {
  ThemeData get theme      => Theme.of(this);
  ColorScheme get colors   => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  MediaQueryData get media => MediaQuery.of(this);
  double get screenWidth   => media.size.width;
  double get screenHeight  => media.size.height;
  bool get isRtl           => Directionality.of(this) == TextDirection.rtl;
}
