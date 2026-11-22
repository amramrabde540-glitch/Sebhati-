# سبحتي (Flutter)

## البناء بأمر واحد
ثبّت Flutter (https://docs.flutter.dev/get-started/install) ثم من داخل المجلد:

- ويندوز (PowerShell): `.\setup.ps1`
- ماك / لينكس / Git Bash: `bash setup.sh`

السكربت بيعمل: إنشاء مجلد android، ضبط اسم التطبيق، توليد الأيقونة، وبناء الـ APK.
الناتج: `build/app/outputs/flutter-apk/app-release.apk`

## تعديلات سريعة
- **الاسم:** `appName` في أعلى lib/main.dart، وكلمة "سبحتي" في setup.sh و setup.ps1.
- **الأذكار:** القائمة `_adhkar` في lib/main.dart.
- **الأرقام (٣٣ أو 33):** `useArabicDigits` في lib/main.dart.
- **الألوان:** الثوابت اللي أولها `_` تحت `// الألوان`.
- **الأيقونة:** استبدل الصورتين في assets/icon ثم شغّل `dart run flutter_launcher_icons`.

## بناء الـ APK من غير تثبيت أي حاجة (GitHub Actions)
1. اعمل مستودع جديد على github.com وارفع كل ملفات المشروع (بما فيها مجلد `.github`).
2. افتح تبويب **Actions** ← **Build APK** ← **Run workflow**.
3. بعد ~5 دقايق افتح التشغيل الناجح ونزّل **sebhati-apk** من قسم Artifacts، وجواه ملف app-release.apk.
