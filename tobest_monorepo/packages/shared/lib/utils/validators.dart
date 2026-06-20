// packages/shared/lib/utils/validators.dart
//
// دوال التحقق من المدخلات — تُستخدم في جميع الفورمات

/// التحقق من مدخلات النماذج
class AppValidators {
  AppValidators._();

  /// التحقق من الإيميل
  static String? email(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'البريد الإلكتروني مطلوب' : 'Email is required';
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return isRtl ? 'بريد إلكتروني غير صحيح' : 'Invalid email address';
    }
    return null;
  }

  /// التحقق من كلمة المرور
  static String? password(String? value, {bool isRtl = true}) {
    if (value == null || value.isEmpty) {
      return isRtl ? 'كلمة المرور مطلوبة' : 'Password is required';
    }
    if (value.length < 8) {
      return isRtl ? 'يجب أن تكون 8 أحرف على الأقل' : 'Minimum 8 characters';
    }
    return null;
  }

  /// تأكيد تطابق كلمة المرور
  static String? confirmPassword(
    String? value,
    String password, {
    bool isRtl = true,
  }) {
    if (value == null || value.isEmpty) {
      return isRtl ? 'تأكيد كلمة المرور مطلوب' : 'Please confirm password';
    }
    if (value != password) {
      return isRtl ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';
    }
    return null;
  }

  /// التحقق من الاسم
  static String? name(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'الاسم مطلوب' : 'Name is required';
    }
    if (value.trim().length < 2) {
      return isRtl ? 'الاسم قصير جداً' : 'Name too short';
    }
    return null;
  }

  /// التحقق من رقم الهاتف
  static String? phone(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'رقم الهاتف مطلوب' : 'Phone is required';
    }
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) {
      return isRtl ? 'رقم هاتف غير صحيح' : 'Invalid phone number';
    }
    return null;
  }

  /// التحقق من الطول (cm)
  static String? height(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'الطول مطلوب' : 'Height is required';
    }
    final h = double.tryParse(value.trim());
    if (h == null || h < 100 || h > 250) {
      return isRtl ? 'طول غير صحيح (100-250 سم)' : 'Invalid height (100-250 cm)';
    }
    return null;
  }

  /// التحقق من الوزن (kg)
  static String? weight(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'الوزن مطلوب' : 'Weight is required';
    }
    final w = double.tryParse(value.trim());
    if (w == null || w < 30 || w > 300) {
      return isRtl ? 'وزن غير صحيح (30-300 كجم)' : 'Invalid weight (30-300 kg)';
    }
    return null;
  }

  /// التحقق من العمر
  static String? age(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'العمر مطلوب' : 'Age is required';
    }
    final a = int.tryParse(value.trim());
    if (a == null || a < 13 || a > 100) {
      return isRtl ? 'عمر غير صحيح (13-100)' : 'Invalid age (13-100)';
    }
    return null;
  }

  /// التحقق من OTP (6 أرقام)
  static String? otp(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'الرمز مطلوب' : 'Code is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return isRtl ? 'يجب أن يكون الرمز 6 أرقام' : 'Code must be 6 digits';
    }
    return null;
  }

  /// التحقق من حقل عام غير فارغ
  static String? required(
    String? value,
    String fieldName, {
    bool isRtl = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? '$fieldName مطلوب' : '$fieldName is required';
    }
    return null;
  }

  /// التحقق من وزن التمرين
  static String? workoutWeight(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'الوزن مطلوب' : 'Weight is required';
    }
    final w = double.tryParse(value.trim());
    if (w == null || w < 0 || w > 500) {
      return isRtl ? 'وزن غير صحيح' : 'Invalid weight';
    }
    return null;
  }

  /// التحقق من عدد التكرارات
  static String? reps(String? value, {bool isRtl = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRtl ? 'التكرارات مطلوبة' : 'Reps required';
    }
    final r = int.tryParse(value.trim());
    if (r == null || r < 1 || r > 100) {
      return isRtl ? 'عدد غير صحيح' : 'Invalid number';
    }
    return null;
  }
}
