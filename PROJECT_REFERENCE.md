# 🏆 Berita Bola - Project Reference & Scaffold

**📌 BOOKMARK THIS FILE - Always refer to this before any development**

---

## 📱 App Information

- **App Name:** Berita Bola
- **Package Name:** `com.idnkt78.beritabola`
- **Version:** 1.0.0
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 35 (Android 15)

---

## 🎯 Core Features

### 1. Authentication System
- ✅ Email/Password (Register & Login)
- ✅ Google Sign-In
- ✅ Anonymous Mode (Firebase Anonymous Auth)
- ✅ Account Linking:
  - Email → Google (automatic)
  - Google → Email (manual with password setup)

### 2. WordPress Content (API: https://beritabola.app)
- ✅ Fetch articles from WordPress REST API
- ✅ Article list with pagination
- ✅ Article detail page
- ✅ Comments system:
  - Read comments
  - Post comments (authenticated & anonymous)
  - Reply to comments (nested, max 3 levels)
  - Anonymous users display as "Anonym"

### 3. Live Sports Data (API: https://www.api-football.com/)
- ✅ Live scores
- ✅ Match details
- ✅ League details
- ✅ Player details

### 4. Push Notifications (OneSignal)
- ✅ New article notifications
- ✅ Match update notifications
- ✅ Comment reply notifications

### 5. User Profile & Settings
- ✅ View profile
- ✅ Link/unlink accounts
- ✅ Set password for Google users
- ✅ Dark/Light theme toggle
- ✅ Notification preferences

### 6. Future Features (Database Structure Ready)
- 🔄 Bookmark/favorite articles
- 🔄 Follow teams/players
- 🔄 Search functionality

---

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── config/
│   ├── app_config.dart               # API keys, endpoints
│   ├── theme_config.dart             # Dark/Light theme
│   └── route_config.dart             # App routes
├── models/
│   ├── user_model.dart               # User data model
│   ├── article_model.dart            # WordPress article
│   ├── comment_model.dart            # Comment & replies
│   ├── match_model.dart              # Match data
│   ├── league_model.dart             # League data
│   └── player_model.dart             # Player data
├── services/
│   ├── auth_service.dart             # Firebase Auth
│   ├── wordpress_service.dart        # WordPress API
│   ├── football_api_service.dart     # API-Football
│   ├── firestore_service.dart        # Firestore CRUD
│   ├── onesignal_service.dart        # Push notifications
│   └── theme_service.dart            # Theme management
├── providers/
│   ├── auth_provider.dart            # Auth state management
│   ├── theme_provider.dart           # Theme state
│   └── article_provider.dart         # Articles state
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── set_password_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── navigation_wrapper.dart
│   ├── articles/
│   │   ├── article_list_screen.dart
│   │   ├── article_detail_screen.dart
│   │   └── widgets/comment_widget.dart
│   ├── sports/
│   │   ├── live_scores_screen.dart
│   │   ├── match_detail_screen.dart
│   │   ├── league_detail_screen.dart
│   │   └── player_detail_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── settings_screen.dart
└── widgets/
    ├── loading_widget.dart
    ├── error_widget.dart
    └── empty_state_widget.dart
```

---

## 🗄️ Database Structure (Firestore)

### Collection: `users`
```json
{
  "userId": "string (UID)",
  "email": "string",
  "displayName": "string",
  "phoneNumber": "string | null",
  "photoURL": "string | null",
  "isAnonymous": "boolean",
  "linkedProviders": ["email", "google.com"],
  "notificationSubscribed": "boolean",
  "fcmToken": "string",
  "oneSignalUserId": "string",
  "theme": "light | dark | system",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Collection: `comments` (cached from WordPress)
```json
{
  "commentId": "string (WordPress ID)",
  "articleId": "string",
  "userId": "string (Firebase UID)",
  "authorName": "string",
  "content": "string",
  "parentId": "string | null",
  "level": "number (0-2, max 3 levels)",
  "createdAt": "timestamp"
}
```

### Collection: `bookmarks` (future)
```json
{
  "userId": "string",
  "articleId": "string",
  "savedAt": "timestamp"
}
```

### Collection: `team_follows` (future)
```json
{
  "userId": "string",
  "teamId": "string",
  "followedAt": "timestamp"
}
```

---

## 🔌 API Endpoints

### WordPress REST API
- **Base URL:** `https://beritabola.app/wp-json/wp/v2/`
- **Articles:** `GET /posts`
- **Article Detail:** `GET /posts/{id}`
- **Comments:** `GET /comments?post={id}`
- **Post Comment:** `POST /comments`

### API-Football
- **Base URL:** `https://v3.football.api-sports.io/`
- **Headers:** `x-rapidapi-key: YOUR_API_KEY`
- **Live Matches:** `GET /fixtures?live=all`
- **Match Detail:** `GET /fixtures?id={id}`
- **League:** `GET /leagues?id={id}`
- **Player:** `GET /players?id={id}`

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.5.1
  firebase_analytics: ^11.3.5
  
  # Google Sign-In
  google_sign_in: ^6.2.2
  
  # OneSignal
  onesignal_flutter: ^5.2.7
  
  # HTTP & API
  http: ^1.2.0
  dio: ^5.7.0
  
  # State Management
  provider: ^6.1.2
  
  # UI
  cached_network_image: ^3.4.1
  flutter_html: ^3.0.0-beta.2
  
  # Local Storage
  shared_preferences: ^2.3.3
  
  # Utils
  intl: ^0.20.1
  timeago: ^3.7.0
  
  # Tracking SDKs
  facebook_app_events: ^0.19.2
  appsflyer_sdk: ^6.15.0
  # tiktok_sdk: (custom implementation)
```

---

## 🔐 Keystore Information

**Location:** `android/app/keystore.jks`

**Details:**
- Store Password: `[SECURE]`
- Key Alias: `beritabola`
- Key Password: `[SECURE]`

**Gradle Reference:**
```gradle
signingConfigs {
    release {
        storeFile file('keystore.jks')
        storePassword System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties['storePassword']
        keyAlias System.getenv("KEY_ALIAS") ?: keystoreProperties['keyAlias']
        keyPassword System.getenv("KEY_PASSWORD") ?: keystoreProperties['keyPassword']
    }
}
```

---

## 🎨 Theme Configuration

### Light Theme
- **Primary Color:** Blue (#2196F3)
- **Secondary Color:** Orange (#FF9800)
- **Background:** White (#FFFFFF)
- **Surface:** Grey 50 (#FAFAFA)

### Dark Theme
- **Primary Color:** Blue (#42A5F5)
- **Secondary Color:** Orange (#FFB74D)
- **Background:** Grey 900 (#121212)
- **Surface:** Grey 800 (#1E1E1E)

---

## 🚀 Development Workflow

### 1. Setup
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Run
```bash
flutter run
```

### 3. Build Release
```bash
flutter build apk --release
flutter build appbundle --release
```

### 4. Hot Reload/Restart
- Hot Reload: `r`
- Hot Restart: `R`
- Quit: `q`

---

## ✅ Implementation Checklist

### Phase 1: Foundation (Week 1)
- [ ] Project setup with correct package name
- [ ] Firebase configuration
- [ ] Theme system (dark/light)
- [ ] Navigation structure
- [ ] Auth screens (login, register)

### Phase 2: Authentication (Week 1)
- [ ] Email/password auth
- [ ] Google sign-in
- [ ] Anonymous auth
- [ ] Account linking
- [ ] User profile screen

### Phase 3: Content (Week 2)
- [ ] WordPress API integration
- [ ] Article list with pagination
- [ ] Article detail screen
- [ ] Comments display
- [ ] Post comment functionality
- [ ] Nested comments (max 3 levels)

### Phase 4: Sports Data (Week 2-3)
- [ ] API-Football integration
- [ ] Live scores screen
- [ ] Match detail screen
- [ ] League detail screen
- [ ] Player detail screen

### Phase 5: Notifications (Week 3)
- [ ] OneSignal setup
- [ ] Push notification handling
- [ ] Notification preferences

### Phase 6: Tracking SDKs (Week 3)
- [ ] Firebase Analytics
- [ ] Facebook SDK
- [ ] AppsFlyer
- [ ] TikTok SDK

### Phase 7: Polish & Testing (Week 4)
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Testing on multiple devices
- [ ] Performance optimization

---

## 🐛 Known Issues & Solutions

### Issue: Firestore "document not found"
**Solution:** Use `.set()` instead of `.update()` for first-time users

### Issue: Google Sign-In returns null
**Solution:** Check SHA-1/SHA-256 in Firebase Console

### Issue: Comments not nested correctly
**Solution:** Check `parent` field and `level` calculation

---

## 📝 Code Standards

1. **Naming:**
   - Classes: `PascalCase`
   - Variables: `camelCase`
   - Files: `snake_case.dart`
   - Constants: `UPPER_SNAKE_CASE`

2. **File Structure:**
   - One class per file
   - Group related files in folders
   - Use `index.dart` for exports

3. **Error Handling:**
   - Always use try-catch for API calls
   - Show user-friendly error messages
   - Log errors for debugging

4. **Comments:**
   - Use `///` for documentation
   - Use `//` for inline comments
   - Explain WHY, not WHAT

---

## 🔗 Important Links

- **WordPress Site:** https://beritabola.app
- **API-Football Docs:** https://www.api-football.com/documentation-v3
- **Firebase Console:** https://console.firebase.google.com/project/beritabola-8bccc
- **OneSignal Dashboard:** https://app.onesignal.com
- **Play Store Console:** (TBD)

---

## 📞 Support

For any questions or issues:
1. Check this reference document first
2. Review the existing code structure
3. Test in isolation before integrating

---

**Last Updated:** November 17, 2025
**Version:** 1.0.0 - Fresh Start
