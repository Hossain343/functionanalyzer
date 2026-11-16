# math a (Wear OS & Flutter)

این پوشه شامل تمام فایل‌های آماده برای ساخت مستقیم خروجی **APK ساعت Wear OS** از طریق **GitHub Actions** است.

## محتویات پوشه
- `.github/workflows/build_wear_apk.yml` — ورک‌فلو خودکار بیلد Flutter و ساخت خروجی Release APK
- `pubspec.yaml` — پکیج‌های پروژه (`math_expressions`)
- `wear_config/AndroidManifest.xml` — مانیفست تنظیم‌شده با نام `math a` برای ساعت هوشمند (`watch` + `standalone`)
- `lib/` — سورس‌کد کامل ماژولار Dart

## نحوه استفاده در GitHub
1. یک مخزن (Repository) جدید در GitHub بسازید.
2. **تمام محتویات داخل پوشه `github`** (شامل پوشه مخفی `.github`، `lib`، `wear_config` و `pubspec.yaml`) را در ریشه مخزن خود آپلود/Push کنید.
3. وارد تب **Actions** در مخزن GitHub خود شوید؛ ورک‌فلو `Build Wear OS APK` خودکار اجرا می‌شود (یا دکمه **Run workflow** را بزنید).
4. پس از سبز شدن بیلد، پایین صفحه اجرا در بخش **Artifacts** فایل `math-a-WearOS-APK` را دانلود و روی ساعت/گوشی نصب کنید.
