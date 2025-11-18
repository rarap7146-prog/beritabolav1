# ⚡ Quick Commands

## 🚀 Run App
```bash
flutter run
```

## 🔄 Hot Reload
Press `r` in terminal (while app is running)

## 🔃 Hot Restart
Press `R` in terminal

## 📦 Get Dependencies
```bash
flutter pub get
```

## 🧹 Clean Build
```bash
flutter clean
flutter pub get
```

## 🏗️ Build Release
```bash
# APK
flutter build apk --release

# App Bundle
flutter build appbundle --release
```

## 📱 List Devices
```bash
flutter devices
```

## 🔍 Check for Issues
```bash
flutter doctor
```

## 📊 Analyze Code
```bash
flutter analyze
```

## 🧪 Run Tests
```bash
flutter test
```

---

## 🛠️ Common Tasks

### Add New Package
1. Edit `pubspec.yaml`
2. Add package under `dependencies:`
3. Run: `flutter pub get`

### Fix Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

### Check Package Versions
```bash
flutter pub outdated
```

### Update Packages
```bash
flutter pub upgrade
```

---

## 📝 Git Commands

### Initialize Git
```bash
git init
git add .
git commit -m "Fresh start - v1.0"
```

### Push to GitHub
```bash
git remote add origin YOUR_REPO_URL
git branch -M main
git push -u origin main
```

---

## 🔐 Environment Setup

### Add API Keys
Create `lib/config/api_keys.dart`:
```dart
class ApiKeys {
  static const String wordpressBase = 'https://beritabola.app/wp-json/wp/v2/';
  static const String footballApiKey = 'YOUR_API_KEY';
  static const String oneSignalAppId = 'YOUR_APP_ID';
}
```

**⚠️ Never commit this file!** (Already in .gitignore)

---

**Quick Ref Created:** November 17, 2025
