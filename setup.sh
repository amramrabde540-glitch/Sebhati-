#!/usr/bin/env bash
# تشغيل: bash setup.sh   (macOS / Linux / Git Bash على ويندوز)
set -e

flutter create --project-name sebhati --org com.sebhati --platforms=android .
rm -rf test

# اسم التطبيق على الموبايل
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i.bak 's/android:label="[^"]*"/android:label="سبحتي"/' "$MANIFEST"
rm -f "$MANIFEST.bak"

flutter pub get
dart run flutter_launcher_icons
flutter build apk --release

echo
echo "تم. الملف: build/app/outputs/flutter-apk/app-release.apk"
