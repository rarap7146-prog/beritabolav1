# 🤖 GitHub Copilot Instructions - Berita Bola

> **Priority Reference**: Always consult `PROJECT_REFERENCE.md` for complete project details before generating code.

---

## 🎯 Project Overview

**Berita Bola** is a Flutter mobile application for Indonesian football news and live scores, combining WordPress content with real-time sports data.

### Core Identity
- **Package Name**: `com.idnkt78.beritabola`
- **Version**: 1.0.0
- **Platform**: Android (Min SDK 21, Target SDK 35)
- **Primary Language**: Dart/Flutter
- **State Management**: Provider pattern

---

## 🏗️ Architecture Principles

### 1. Project Structure (Mandatory)
```
lib/
├── main.dart                    # Entry point with Firebase init
├── config/                      # Configuration & constants
│   ├── app_config.dart         # API endpoints, keys (gitignored)
│   ├── theme_config.dart       # Material theme definitions
│   └── route_config.dart       # Named routes
├── models/                      # Data models (JSON serializable)
│   ├── user_model.dart
│   ├── article_model.dart
│   ├── comment_model.dart
│   ├── match_model.dart
│   ├── league_model.dart
│   └── player_model.dart
├── services/                    # Business logic & API
│   ├── auth_service.dart       # Firebase Auth operations
│   ├── wordpress_service.dart  # WordPress REST API
│   ├── football_api_service.dart # API-Football integration
│   ├── firestore_service.dart  # Firestore CRUD
│   ├── onesignal_service.dart  # Push notifications
│   └── theme_service.dart      # Theme persistence
├── providers/                   # State management
│   ├── auth_provider.dart      # Authentication state
│   ├── theme_provider.dart     # Theme state
│   └── article_provider.dart   # Content state
├── screens/                     # UI screens
│   ├── auth/                   # Login, register, set password
│   ├── home/                   # Home screen, navigation
│   ├── articles/               # Article list, detail, comments
│   ├── sports/                 # Live scores, match details
│   └── profile/                # User profile, settings
└── widgets/                     # Reusable components
    ├── loading_widget.dart
    ├── error_widget.dart
    └── empty_state_widget.dart
```

### 2. Naming Conventions (Strict)
- **Files**: `snake_case.dart` (e.g., `article_detail_screen.dart`)
- **Classes**: `PascalCase` (e.g., `ArticleDetailScreen`)
- **Variables/Functions**: `camelCase` (e.g., `fetchArticles`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `API_BASE_URL`)
- **Private members**: Prefix with `_` (e.g., `_initializeApp`)

### 3. File Organization Rules
- **One class per file** (except small helper classes)
- **Barrel files**: Use `index.dart` for exporting multiple files
- **Widget files**: Place widget-specific files in `widgets/` subfolder within screen directory

---

## 🔌 API Integrations

### WordPress REST API
```dart
// Base URL: https://beritabola.app/wp-json/wp/v2/
// Endpoints:
// - GET /posts?per_page=10&page=1
// - GET /posts/{id}
```

**Important Notes**:
- Use pagination for article lists
- Handle nested comments (max 3 levels: 0, 1, 2)
- Anonymous users display as "Anonym" in comments
- Cache frequently accessed articles in Firestore

### API-Football
```dart
// Base URL: https://v3.football.api-sports.io/
// Required Header: x-rapidapi-key: YOUR_API_KEY
// Main Endpoints:
// - GET /fixtures?live=all (live matches)
// - GET /fixtures?id={id} (match details)
// - GET /leagues?id={id}
// - GET /players?id={id}
```

**Rate Limits**: Be mindful of API quotas, implement caching

---

## 🔐 Authentication Flow

### Supported Methods
1. **Email/Password**: Standard Firebase auth
2. **Google Sign-In**: OAuth with Firebase
3. **Anonymous**: Guest mode with optional account linking

### Account Linking Logic
```dart
// CRITICAL: Implement these scenarios
// 1. Anonymous → Email (with password)
// 2. Anonymous → Google (automatic)
// 3. Email → Google (automatic merge)
// 4. Google → Email (manual password setup)
```

**Firestore User Document** (Always sync on auth changes):
```dart
{
  userId: uid,
  email: email,
  displayName: displayName,
  isAnonymous: bool,
  linkedProviders: ['email', 'google.com'],
  theme: 'light' | 'dark' | 'system',
  notificationSubscribed: bool,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## 🎨 UI/UX Guidelines

### Theme System
- **Support**: Light, Dark, System (auto-detect)
- **Persistence**: Save preference in `shared_preferences`
- **Colors**:
  - **Light**: Primary Blue (#2196F3), Secondary Orange (#FF9800)
  - **Dark**: Primary Blue (#42A5F5), Secondary Orange (#FFB74D)

### Material Design
- Use Material 3 components (`useMaterial3: true`)
- Follow Flutter best practices for responsive design
- Support safe areas and notches

### Loading States
```dart
// Always implement:
// 1. Initial loading (CircularProgressIndicator)
// 2. Pagination loading (bottom indicator)
// 3. Pull-to-refresh
// 4. Empty states with meaningful messages
// 5. Error states with retry button
```

---

## 📝 Code Generation Rules

### When Creating Services
```dart
// Template for all service classes
class SomeService {
  // Singleton pattern
  static final SomeService _instance = SomeService._internal();
  factory SomeService() => _instance;
  SomeService._internal();

  // Methods with error handling
  Future<Result> someMethod() async {
    try {
      // Implementation
      return result;
    } catch (e) {
      print('Error in SomeService.someMethod: $e');
      rethrow; // Or return error state
    }
  }
}
```

### When Creating Models
```dart
// Always include:
// 1. fromJson factory constructor
// 2. toJson method
// 3. copyWith method (optional but recommended)
// 4. toString override (for debugging)

class ArticleModel {
  final String id;
  final String title;
  
  ArticleModel({required this.id, required this.title});
  
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'].toString(),
      title: json['title']['rendered'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
```

### When Creating Providers
```dart
// Use ChangeNotifier pattern
class SomeProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch data
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### When Creating Screens
```dart
// StatefulWidget for screens with state
// StatelessWidget for simple displays
class SomeScreen extends StatefulWidget {
  const SomeScreen({Key? key}) : super(key: key);
  
  @override
  State<SomeScreen> createState() => _SomeScreenState();
}

class _SomeScreenState extends State<SomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Title')),
      body: SafeArea(child: Container()),
    );
  }
}
```

---

## 🔥 Firebase Configuration

### Required Services
- **Firebase Auth**: Email, Google, Anonymous
- **Cloud Firestore**: Users, comments (cache)
- **Firebase Analytics**: Event tracking
- **Firebase Cloud Messaging**: Via OneSignal

### Firestore Collections
```dart
// users: User profiles
// comments: Cached WordPress comments
// bookmarks: (Future) Saved articles
// team_follows: (Future) Followed teams
```

### Security Rules Mindset
- Users can only update their own documents
- Comments are public read, auth write
- Validate data on server-side when possible

---

## 📱 Push Notifications (OneSignal)

### Integration Points
1. **Initialize** in `main.dart` after Firebase
2. **Subscribe/Unsubscribe** from user settings
3. **Handle notifications**:
   - New articles → Open article detail
   - Match updates → Open match detail
   - Comment replies → Open article with comment

### User Preferences
- Store `notificationSubscribed` in Firestore
- Sync with OneSignal subscription status

---

## 🐛 Error Handling Strategy

### Always Implement
```dart
try {
  // Risky operation
} on FirebaseAuthException catch (e) {
  // Firebase-specific errors
  _showError(e.message ?? 'Authentication failed');
} on SocketException {
  // Network errors
  _showError('No internet connection');
} catch (e) {
  // Generic errors
  _showError('Something went wrong: $e');
  print('Unexpected error: $e');
}
```

### User-Facing Messages
- **Network errors**: "Check your internet connection"
- **Auth errors**: Use Firebase error messages
- **API errors**: "Unable to load data. Please try again."
- **Unknown errors**: "Something went wrong. Please restart the app."

---

## 🧪 Testing Expectations

### Before Committing
- Run `flutter analyze` (should be clean)
- Test on both light and dark themes
- Test with and without internet
- Test anonymous and authenticated users
- Verify account linking flows

### Key Scenarios to Test
- [ ] Login → Logout → Login again
- [ ] Anonymous → Link to email
- [ ] Anonymous → Link to Google
- [ ] Post comment as authenticated user
- [ ] Post comment as anonymous user
- [ ] Reply to comments (3 levels deep)
- [ ] Toggle theme and restart app
- [ ] Enable/disable notifications

---

## 🚀 Performance Guidelines

### Optimization Rules
1. **Images**: Use `cached_network_image` for all remote images
2. **Lists**: Always use `ListView.builder` or `GridView.builder`
3. **Heavy operations**: Use `compute()` for parsing large JSON
4. **State**: Minimize `notifyListeners()` calls
5. **Navigation**: Use named routes defined in `route_config.dart`

### Memory Management
- Dispose controllers in `dispose()` method
- Cancel streams when widget is disposed
- Use `const` constructors wherever possible

---

## 📦 Dependencies Reference

### Core Dependencies (Already in pubspec.yaml)
```yaml
firebase_core: ^3.8.1          # Firebase initialization
firebase_auth: ^5.3.4          # Authentication
cloud_firestore: ^5.5.1        # Database
firebase_analytics: ^11.3.5    # Analytics
google_sign_in: ^6.2.2         # Google OAuth
onesignal_flutter: ^5.2.7      # Push notifications
http: ^1.2.0                   # HTTP requests
dio: ^5.7.0                    # Advanced HTTP client
provider: ^6.1.2               # State management
cached_network_image: ^3.4.1   # Image caching
flutter_html: ^3.0.0-beta.2    # HTML rendering
shared_preferences: ^2.3.3     # Local storage
intl: ^0.20.1                  # Internationalization
timeago: ^3.7.0                # Relative time
```

### When to Use Each
- **http**: Simple GET/POST requests
- **dio**: Complex requests with interceptors, retry logic
- **provider**: All state management (preferred over setState for complex state)
- **shared_preferences**: User preferences, theme, simple cache

---

## 🔒 Security Best Practices

### API Keys Management
```dart
// NEVER commit to git:
// - lib/config/app_config.dart (contains API keys)
// - android/key.properties (keystore passwords)
// - google-services.json (contains sensitive info)

// Create template files instead:
// - app_config.example.dart
// - key.properties.example
```

### Android Keystore
- **Location**: `android/app/keystore.jks`
- **Alias**: `beritabola`
- **Credentials**: Stored in `android/key.properties` (gitignored)

### Firestore Rules
- Validate user can only modify their own data
- Implement rate limiting for writes
- Sanitize user input before saving

---

## 🎓 Development Workflow

### Before Starting New Feature
1. ✅ Read `PROJECT_REFERENCE.md` for context
2. ✅ Check implementation checklist for phase
3. ✅ Create feature branch: `feature/description`
4. ✅ Update todo list in checklist after completion

### Code Review Checklist
- [ ] Follows naming conventions
- [ ] Proper error handling
- [ ] No hardcoded strings (use constants or i18n)
- [ ] No API keys in code
- [ ] Responsive design (works on different screen sizes)
- [ ] Loading/error/empty states implemented
- [ ] Works in both light and dark themes

### Commit Message Format
```
<type>: <description>

[optional body]

Types: feat, fix, docs, style, refactor, test, chore
Example: feat: implement article comment system
Example: fix: resolve Google Sign-In null error
```

---

## 🎯 Common Code Patterns

### API Call Pattern
```dart
Future<List<Article>> fetchArticles({int page = 1}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/posts?page=$page'),
    );
    
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Article.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load articles');
    }
  } catch (e) {
    print('Error fetching articles: $e');
    rethrow;
  }
}
```

### Provider Pattern
```dart
// In screen:
final provider = Provider.of<SomeProvider>(context);
// Or listen: false for methods
final provider = Provider.of<SomeProvider>(context, listen: false);

// Better: Use Consumer for specific rebuilds
Consumer<SomeProvider>(
  builder: (context, provider, child) {
    return Text(provider.data);
  },
)
```

### Navigation Pattern
```dart
// Push
Navigator.pushNamed(context, '/article-detail', arguments: articleId);

// Pop
Navigator.pop(context);

// Replace
Navigator.pushReplacementNamed(context, '/home');
```

---

## 🌟 Feature-Specific Guidelines

### Comments System
- **Max nesting**: 3 levels (0 → 1 → 2)
- **Parent tracking**: Use `parentId` field
- **Anonymous users**: Display as "Anonym" (not "Anonymous")
- **Validation**: Minimum 3 characters for comment text

### Article List
- **Pagination**: 10 items per page
- **Pull-to-refresh**: Refresh first page
- **Load more**: Detect scroll to bottom
- **Cache**: Store in Firestore for offline access

### Live Scores
- **Refresh interval**: 30 seconds for live matches
- **Status indicators**: Live (pulsing), Finished, Scheduled
- **Timezone**: Convert to user's local timezone

---

## 🎨 Widget Library (Reusable)

### LoadingWidget
```dart
// Use for: Any loading state
LoadingWidget(message: 'Loading articles...')
```

### ErrorWidget
```dart
// Use for: Error states with retry
ErrorWidget(
  message: 'Failed to load data',
  onRetry: () => fetchData(),
)
```

### EmptyStateWidget
```dart
// Use for: Empty lists/results
EmptyStateWidget(
  icon: Icons.article,
  message: 'No articles found',
)
```

---

## 🔗 External Resources

- **WordPress REST API**: https://beritabola.app/wp-json/wp/v2/
- **API-Football Docs**: https://www.api-football.com/documentation-v3
- **Firebase Console**: https://console.firebase.google.com/project/beritabola-8bccc
- **OneSignal Dashboard**: https://app.onesignal.com
- **Flutter Docs**: https://docs.flutter.dev

---

## 🚨 Critical Reminders

1. **ALWAYS** check `PROJECT_REFERENCE.md` before implementing features
2. **NEVER** commit API keys or credentials
3. **ALWAYS** handle errors gracefully with user-friendly messages
4. **ALWAYS** test with anonymous users (they're first-class citizens)
5. **ALWAYS** support both light and dark themes
6. **ALWAYS** implement loading/error/empty states
7. **ALWAYS** use proper null safety (`?`, `!`, `??`)
8. **ALWAYS** dispose resources in `dispose()` method

---

## 💡 When in Doubt

1. Check `PROJECT_REFERENCE.md` for architecture decisions
2. Check `COMMANDS.md` for quick Flutter commands
3. Check `GETTING_STARTED.md` for setup instructions
4. Follow existing patterns in the codebase
5. Ask before making architectural changes

---

**Last Updated**: November 17, 2025
**Version**: 1.0.0
**Status**: Active Development

---

## 🎯 Quick Decision Tree

```
Need to add a feature?
├─ Is it in PROJECT_REFERENCE.md?
│  ├─ Yes → Follow the specified architecture
│  └─ No → Check if it fits the existing structure
│
Need to fetch data?
├─ Is it from WordPress? → Use WordPressService
├─ Is it from API-Football? → Use FootballApiService
└─ Is it user data? → Use FirestoreService
│
Need to manage state?
├─ Is it app-wide? → Create a Provider
├─ Is it screen-specific? → Use StatefulWidget
└─ Is it simple? → Use setState
│
Need to style something?
├─ Check ThemeConfig for colors
├─ Use Theme.of(context) for dynamic theming
└─ Support both light and dark themes
│
Got an error?
├─ Wrap in try-catch
├─ Log for debugging
├─ Show user-friendly message
└─ Provide retry option if applicable
```

---

**🎯 Golden Rule**: When Copilot generates code, it should be production-ready, following all conventions, with proper error handling, and supporting all user types (authenticated, anonymous, Google users).
