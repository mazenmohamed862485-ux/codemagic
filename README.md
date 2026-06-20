# TO Best Flutter Monorepo

نظام Flutter متكامل لأكاديمية TO Best يتكون من تطبيقين وحزمة مشتركة.

---

## 🏗️ هيكل المشروع

```
tobest_monorepo/
├── apps/
│   ├── tobest/              # تطبيق المستخدمين (USER + COACH)
│   └── tobest_management/   # تطبيق الإدارة (MANAGER + SUPPORT + SUBSCRIPTIONS)
├── packages/
│   └── shared/              # الحزمة المشتركة (Domain + Data + Design + Utils)
└── codemagic.yaml           # Codemagic CI/CD (CI + إصدار TO Best + إصدار Management)
```

---

## 🚀 البدء السريع

### المتطلبات
- Flutter ≥ 3.44.0
- Dart ≥ 3.3.0
- Melos: `dart pub global activate melos`

### الإعداد
```bash
git clone <repo>
cd tobest_monorepo

# تهيئة Melos
melos bootstrap

# توليد الكود (Isar + Riverpod)
melos run generate

# إنشاء ملف الأسرار (ضروري قبل التشغيل)
cp packages/shared/lib/config/secrets.dart.example \
   packages/shared/lib/config/secrets.dart
# ثم أدخل القيم الحقيقية
```

### تشغيل التطبيق
```bash
# TO Best
cd apps/tobest
flutter run

# Management
cd apps/tobest_management
flutter run
```

---

## 🔐 إدارة الأسرار

**⚠️ مهم جداً:**

- `packages/shared/lib/config/secrets.dart` في `.gitignore` دائماً
- القيم الحقيقية تُدار من شاشة الإعدادات في تطبيق Management (MANAGER فقط)
- تُخزَّن في `FlutterSecureStorage` (مشفرة على الجهاز)
- في CI/CD تُقرأ من Codemagic Environment Variables (مجموعات: `app_secrets`, keystores `tobest_keystore`/`management_keystore`, `github_credentials`)

### Codemagic Environment Variables / Code Signing المطلوبة
انظر `CODEMAGIC_MIGRATION.md` للتفاصيل الكاملة وخطوات الإعداد في واجهة Codemagic.

| المتغيّر / الهوية | المجموعة | الوصف |
|--------|---------|-------|
| `GAS_BASE_URL` | `app_secrets` | رابط Google Apps Script |
| `GAS_SECRET_KEY` | `app_secrets` | مفتاح التوثيق مع GAS |
| `GEMINI_API_KEY` | `app_secrets` | مفتاح Gemini AI |
| `tobest_keystore` | Android keystore identity | Keystore لـ TO Best (يُرفع كملف، لا كـ Base64) |
| `management_keystore` | Android keystore identity | Keystore لـ Management (يُرفع كملف، لا كـ Base64) |
| `GITHUB_TOKEN` | `github_credentials` | صلاحية الكتابة لإصدار GitHub Releases من Codemagic |

---

## 📦 الحزمة المشتركة (shared)

```
packages/shared/lib/
├── config/           # app_config.dart + secrets.dart
├── domain/
│   ├── entities/     # UserEntity, WorkoutEntity, NutritionEntity...
│   └── repositories/ # Abstract interfaces
├── data/
│   ├── models/       # Isar schemas (@Collection)
│   └── datasources/  # Remote (GAS) + Local (Isar)
├── infrastructure/
│   ├── gas_client.dart       # HTTP client مع Retry
│   ├── isar_service.dart     # قاعدة البيانات المحلية
│   ├── video_service*.dart   # فيديو + Cache
│   ├── notification_service  # Local Notifications
│   ├── polling_service       # Adaptive Polling للشات
│   ├── background_service    # workmanager
│   └── sync_service          # Field-Level Merge مع GAS
├── design/
│   ├── tokens.dart           # ألوان + مسافات + typography
│   ├── themes.dart           # 5 ثيمات
│   └── widgets/
│       └── breathing_animation.dart  # Loading + Rest Timer
└── utils/
    ├── evaluator.dart         # ترجمة evaluator.js كاملاً
    ├── validators.dart        # فحص المدخلات
    └── extensions.dart        # Extensions مفيدة
```

---

## 🎯 ميزات TO Best

| الميزة | التفاصيل |
|--------|---------|
| التمارين | Accordion + Video Carousel + Set Logging + Rest Timer |
| التقييم | محرك evaluate() مُرجَّم من JS — s1/s2/s3/rv/gd/st/ws/dn/beg |
| التغذية | محلل نص عربي + Fuzzy Match + اقتراح وجبة + حلقات ماكرو |
| الشات | Adaptive Polling + Reply + Delete + Image + Voice |
| AI Coach | Gemini 1.5 Flash مع context المستخدم |
| الصحة | Pedometer + نوم + قياسات + Navy Method |
| التقدم | PR History + Steps Chart + Body Chart + Heatmap |
| 5 ثيمات | Auto/Light/Dark/Blue/Pink |
| Offline | Isar + Field-Level Merge + Weekly Cleanup |

## 🎯 ميزات Management

| الدور | الصلاحيات |
|------|----------|
| MANAGER | كل شيء + إعدادات الاتصال + تعيين كوتشات + إيرادات |
| SUPPORT | عرض المستخدمين + طلب تعديل اشتراك |
| SUBSCRIPTIONS | الموافقة/الرفض على طلبات الاشتراك |

---

## 🔄 CI/CD

ينفّذ المشروع الآن على **Codemagic** عبر ملف `codemagic.yaml` في جذر المشروع (التفاصيل الكاملة في `CODEMAGIC_MIGRATION.md`). إعدادات GitHub Actions القديمة محفوظة للمرجعية في `.github/workflows-archived-github-actions/`.

### Workflows
| Workflow | الوصف | المُحرِّك |
|----------|-------|----------|
| `tobest-ci` | Analyze + Format + Test لكل الـ workspace | كل push/PR على main أو develop |
| `tobest-android-release` | بناء وتوقيع وإصدار APK لـ TO Best | `git tag v1.0.0-tobest && git push origin v1.0.0-tobest` |
| `management-android-release` | بناء وتوقيع وإصدار APK لـ Management | `git tag v1.0.0-management && git push origin v1.0.0-management` |

### Weekly Cleanup Flow
```
1. Sync Local → GAS (لا تُحذف بيانات قبل الرفع)
2. Clear Isar + Video Cache
3. Sync GAS → Local (استعادة كاملة)
```

---

## 📱 نشر التطبيق

الـ APK يُنتج كـ GitHub Release Asset تلقائياً.
الفريق يثبته مباشرة (لا متجر).

---

## ⚠️ ملاحظات تقنية

- **Google Drive Streaming**: لا يدعم HTTP Range بالكامل — Seeking محدود
- **Polling vs WebSocket**: اختيار واعٍ — GAS لا يدعم WebSocket
- **Video URL**: لا يظهر في الـ UI أبداً — يُمرَّر مباشرة لـ VideoPlayerController
- **secrets.dart**: في `.gitignore` — يُنشأ يدوياً أو من CI

---

## 🔧 سجل الإصلاحات (Audit Fix Session)

تم تطبيق التدقيق الكامل (tobest_audit_report_v3.md) وإصلاح جميع المشاكل الحرجة والكبرى:

### إصلاحات حرجة (Critical)
- **C-2/C-3**: ملفات Android/iOS الكاملة (Gradle, Manifest, MainActivity, Info.plist)
- **C-4**: ترحيل كامل من Isar v3 (غير متوافق مع Dart 3.x) إلى **drift v2.18**
- **C-5**: إصلاح imports موضوعة بعد تعريفات classes (خطأ Dart syntax) في auth_provider.dart و router.dart
- **C-8**: إنشاء secrets.dart.example
- **C-9**: pubspec.yaml مُصحَّح بالكامل (إزالة isar، إضافة drift)
- **C-10**: إصلاح GitHub Actions heredoc مع `${{ }}` (استخدام printf + env vars)
- **C-11/C-12**: تنفيذ حقيقي لـ `_saveToDb` و `_saveWorkoutLogLocally` (كانت placeholders)
- **C-13**: إنشاء 5 شاشات مفقودة (Devices, SleepLog, Measurements, Health, ResetPassword)
- **C-14**: تصحيح مسار الشات في AppRoutes
- **C-15**: تصحيح مسار .gitignore لملف secrets.dart
- **C-16**: إضافة Authorization Bearer token لكل طلبات GAS

### إصلاحات إضافية اكتُشفت أثناء التنفيذ
- 🐛 **Private type mismatch**: `_PerformancePoint` كانت خاصة بمكتبتين مختلفتين (evaluator.dart و workout_provider.dart) — Dart يعتبرهما نوعين مختلفين تماماً، مما يكسر builds. تم توحيدها كـ `PerformancePoint` عامة.
- 🐛 **Self-import bug**: `chat_screen.dart` كان يستورد نفسه
- 🐛 **Invalid in-function imports**: عبارات `import` داخل أجسام الدوال (خطأ syntax) في 3 ملفات
- 🐛 **Scattered imports**: ملفات مُجمَّعة (`home_widgets.dart`, `progress_widgets.dart`) كانت تحتوي imports متكررة وسط الملف بعد تعريفات classes
- 🐛 **part directive mismatch**: `pr_list.g.dart` لا يطابق اسم الملف الفعلي `progress_widgets.dart`
- 🐛 **Fake FLAG_SECURE**: شاشة OTP كانت تستخدم `SystemUiMode.immersive` (يُخفي شريط الحالة فقط) بدلاً من حماية حقيقية ضد لقطات الشاشة — أُضيف `SecureScreenService` بـ `flutter_windowmanager` الحقيقي
- 🐛 **Missing collection import**: `firstOrNull` بدون `package:collection`
- 🐛 **Fragile JSON encoding**: استخدام `.toString()` على Lists بدل `jsonEncode()` الصريح
- 🐛 **Schema mismatch**: `FoodItem` entity لم يكن يطابق حقول قاعدة الأطعمة الحقيقية (دليل_القيم_الغذائية.jsonl) — أُعيد بناؤه بالحقول الصحيحة (category, state, preparationMethod, إلخ)
- 🐛 **Dead Isar references**: 8 ملفات Isar models قديمة حُذفت بالكامل بعد الترحيل لـ drift

### قاعدة الأطعمة
- تحويل 11,000 عنصر من `دليل_القيم_الغذائية.jsonl` إلى `assets/food_database.json` (11.2MB)
- `FoodSeedingService` يزرع البيانات في drift عند أول تشغيل فقط

### الاختبارات
- `evaluator_test.dart`: 25+ اختبار وحدة لكل دوال Evaluator (Epley, evaluate, parseMealText, BMR, Navy Body Fat...)
- `validators_test.dart`: اختبارات شاملة لكل الـ Validators
