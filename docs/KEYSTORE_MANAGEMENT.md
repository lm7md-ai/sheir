# دليل إدارة مفتاح التوقيع الدائم والنسخ الاحتياطي (Keystore Management & Backup)

تتطلب أجهزة أندرويد توقيع كل حزمة APK بمفتاح تشفيري مستقر. لضمان تثبيت أي إصدار وتحديث جديد فوق الإصدار السابق بسلاسة ودون ظهور رسالة خطأ تعارض التوقيع (`App not installed as package appears to be invalid / Signature mismatch`)، يتم اعتماد البروتوكول التالي:

---

## ١. مواصفات مفتاح التوقيع الدائم (Diwan Release Keystore)
- **المسار الافتراضي**: `app/android/app/keystore.jks`
- **خوارزمية المفتاح**: RSA 2048-bit
- **مدة الصلاحية**: 10,000 يوم (حوالي 27 عاماً)
- **الاسم المستعار (Alias)**: `diwan_key`
- **التشفير المستهدف**: SHA-256 with RSA

---

## ٢. كيفية إنشاء المفتاح المرجعي (One-Time Creation)
في بيئة التطوير، يمكنك توليد المفتاح عبر الأمر التالي:
```bash
keytool -genkey -v -keystore app/android/app/keystore.jks \
  -alias diwan_key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass diwan2026pass \
  -keypass diwan2026pass \
  -dname "CN=Diwan, OU=Engineering, O=Diwan, L=Riyadh, C=SA"
```

---

## ٣. كيفية أخذ نسخة احتياطية آمنة (How to Backup the Keystore)
⚠️ **تنبيه حرج**: في حال ضياع ملف `keystore.jks` أو كلمته السرية، لن تتمكن أبداً من تحديث التطبيق على هواتف المستخدمين الحالية، وسيضطر المستخدم لإلغاء تثبيت النسخة القديمة وفقدان تقدمه المحلي.

### خطوات النسخ الاحتياطي:
1. احتفظ بنسخة من ملف `keystore.jks` في وسيط تخزين مشفر وخارجي آمن (مثل 1Password أو Bitwarden أو Google Drive مشفر).
2. قم بتشفير الملف إلى صيغة Base64 لتخزينه في مستودع GitHub Secrets:
   ```bash
   base64 -w 0 app/android/app/keystore.jks > diwan_keystore.base64
   ```
3. توجه إلى إعدادات المستودع على GitHub:
   `Settings` -> `Secrets and variables` -> `Actions` -> `Repository secrets`.
4. أضف المتغيرات السرية الأربعة:
   - `KEYSTORE_BASE64`: محتوى ملف `diwan_keystore.base64`.
   - `KEYSTORE_PASSWORD`: كلمة مرور المستودع (`diwan2026pass`).
   - `KEY_ALIAS`: الاسم المستعار للمفتاح (`diwan_key`).
   - `KEY_PASSWORD`: كلمة مرور المفتاح الخاص (`diwan2026pass`).

---

## ٤. آلية العمل في خط البناء التلقائي (CI/CD Pipeline)
يقوم ملف `.github/workflows/ci.yml` تلقائياً بفك تشفير `KEYSTORE_BASE64` قبل مرحلة `flutter build apk` وتوقيع النسخة النهائية لمعمارية `arm64-v8a` بدقة فائقة لضمان استقرار التثبيت التراكمي الدائم.
