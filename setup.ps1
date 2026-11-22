# تشغيل (PowerShell على ويندوز):  .\setup.ps1
$ErrorActionPreference = "Stop"

flutter create --project-name sebhati --org com.sebhati --platforms=android .
if (Test-Path test) { Remove-Item -Recurse -Force test }

# اسم التطبيق على الموبايل
$m = "android/app/src/main/AndroidManifest.xml"
$t = Get-Content $m -Raw -Encoding UTF8
$t = $t -replace 'android:label="[^"]*"', 'android:label="سبحتي"'
[System.IO.File]::WriteAllText((Resolve-Path $m), $t, (New-Object System.Text.UTF8Encoding $false))

flutter pub get
dart run flutter_launcher_icons
flutter build apk --release

Write-Host ""
Write-Host "تم. الملف: build/app/outputs/flutter-apk/app-release.apk"
