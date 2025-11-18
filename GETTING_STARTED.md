# 🚀 Getting Started - Berita Bola v1

## ✅ What's Been Done

### 1. Fresh Flutter Project Created
- Package name: `com.idnkt78.beritabola`
- Clean slate with proper structure
- All dependencies ready to be added

### 2. Files Copied from Old Project
- ✅ `upload-keystore.jks` → Signing keystore
- ✅ `key.properties` → Keystore credentials (if existed)
- ✅ `google-services.json` → Firebase config (if existed)

### 3. Folder Structure Created
```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── services/        # API & business logic
├── providers/       # State management
├── screens/         # UI screens
│   ├── auth/
│   ├── home/
│   ├── articles/
│   ├── sports/
│   └── profile/
└── widgets/         # Reusable widgets
```

### 4. Documentation
- ✅ `PROJECT_REFERENCE.md` - **BOOKMARK THIS!** Complete project guide

---

## 📋 Next Steps

### Step 1: Open Project in VS Code
1. Close current VS Code window
2. Open: `C:\Users\User\OneDrive\Documents\Tito_script\beritabola\beritabolav1`
3. Open terminal (Ctrl + `)

### Step 2: Add Dependencies
Edit `pubspec.yaml` and add:

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.5.1
  firebase_analytics: ^11.3.5
  
  # Google Sign-In
  google_sign_in: ^6.2.2
  
  # OneSignal
  onesignal_flutter: ^5.2.7
  
  # HTTP
  http: ^1.2.0
  dio: ^5.7.0
  
  # State Management
  provider: ^6.1.2
  
  # UI
  cached_network_image: ^3.4.1
  flutter_html: ^3.0.0-beta.2
  
  # Storage
  shared_preferences: ^2.3.3
  
  # Utils
  intl: ^0.20.1
  timeago: ^3.7.0
```

Then run:
```bash
flutter pub get
```

### Step 3: Configure Android
1. Check if `android/key.properties` exists (keystore credentials)
2. Update `android/app/build.gradle.kts` to use keystore
3. Verify `google-services.json` is in `android/app/`

### Step 4: Start Development
Follow the implementation checklist in `PROJECT_REFERENCE.md`

---

## 🎯 Development Priority

### Phase 1: Foundation (Do First)
1. Theme system (dark/light)
2. Navigation setup
3. Config files (API keys)

### Phase 2: Authentication
1. Login/Register screens
2. Firebase Auth setup
3. Google Sign-In

### Phase 3: Content
1. WordPress API
2. Article list
3. Article detail

### Phase 4: Sports Data
1. API-Football integration
2. Live scores
3. Match details

---

## 📞 Quick Reference

- **Project Root:** `C:\Users\User\OneDrive\Documents\Tito_script\beritabola\beritabolav1`
- **Main Documentation:** `PROJECT_REFERENCE.md`
- **Package Name:** `com.idnkt78.beritabola`
- **WordPress:** https://beritabola.app
- **Football API:** https://www.api-football.com/

---

## ⚠️ Important Notes

1. **Always refer to PROJECT_REFERENCE.md** before coding
2. **Keep keystore file secure** - don't commit to git
3. **Test on real device** for Google Sign-In
4. **Use .env for API keys** (add to .gitignore)

---

**Created:** November 17, 2025
**Status:** Fresh project ready for development 🎉
