# 🔗 Deep Links Implementation Guide

## Overview

Berita Bola app now supports deep linking with both **App Links (https://)** and **Custom Scheme (beritabola://)**.

---

## 📱 Supported Deep Link Patterns

### 1. Article Links (Primary Use Case)
```
https://beritabola.app/article/123
https://beritabola.app/post/123
https://beritabola.app/article-slug-123
https://beritabola.app/123
beritabola://article/123
```

### 2. Category Links (Future)
```
https://beritabola.app/category/liga-inggris
beritabola://category/liga-inggris
```

### 3. Sports Content (Future)
```
https://beritabola.app/match/123456
https://beritabola.app/league/39
https://beritabola.app/player/123
https://beritabola.app/team/456
```

---

## 🛠️ Configuration Files

### 1. Android Manifest
**File**: `android/app/src/main/AndroidManifest.xml`

Deep link intent filters are already configured:
- **App Links**: `https://beritabola.app` and `https://www.beritabola.app`
- **Custom Scheme**: `beritabola://`
- **Auto-verify**: Enabled for App Links

### 2. Asset Links JSON
**File**: `assetlinks.json` (in project root)

This file **MUST BE UPLOADED** to your domain at:
```
https://beritabola.app/.well-known/assetlinks.json
```

**Important**:
- SHA-256 fingerprint: `BD:D9:B2:03:CE:A0:4E:C5:0D:90:BB:37:67:64:BB:C9:6E:7F:96:17:BF:52:44:C6:4D:89:B4:A8:E4:A3:BF:4B`
- Package name: `com.idnkt78.beritabola`
- This is for **DEBUG** builds only
- **Before releasing to production**, generate a release keystore and update the fingerprint

---

## 🔐 Domain Verification Steps

### Step 1: Upload assetlinks.json
1. Upload `assetlinks.json` to your web server
2. Make it accessible at: `https://beritabola.app/.well-known/assetlinks.json`
3. Ensure the file is served with `Content-Type: application/json`
4. Ensure the file is accessible via HTTPS (not HTTP)

### Step 2: Verify Upload
Test the URL in a browser:
```
https://beritabola.app/.well-known/assetlinks.json
```

You should see the JSON content.

### Step 3: Test Deep Links
Use Android Debug Bridge (ADB) to test:

**Test Article Deep Link**:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/123" com.idnkt78.beritabola
```

**Test Custom Scheme**:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "beritabola://article/123" com.idnkt78.beritabola
```

### Step 4: Verify App Links
Google provides a verification tool:
```
https://developers.google.com/digital-asset-links/tools/generator
```

---

## 🎯 Behavior & User Experience

### Article Deep Links
1. **User clicks link** → App opens (if installed) or web browser (if not)
2. **Loading state** → Circular progress indicator
3. **Success** → Navigate to article detail screen
4. **Error** → Show error chip, redirect to home screen

### Authentication Requirements
- **Public content** (articles, matches, etc.): No login required
- **If not logged in**: Content opens normally
- **Future protected content**: User will be redirected to login screen

### Error Handling
- **Article not found**: "Article not found" error chip → Home screen
- **Network error**: "Failed to load article" error chip → Home screen
- **Invalid URL**: "Content not found" error chip → Home screen
- **Unknown content**: Opens in external browser (for ads, external links)

---

## 🔧 Testing Scenarios

### Scenario 1: Article Link (Logged In)
1. User is logged in (email/Google)
2. Click: `https://beritabola.app/article/123`
3. **Expected**: App opens, loading indicator, article detail screen

### Scenario 2: Article Link (Not Logged In)
1. User is anonymous (guest mode)
2. Click: `https://beritabola.app/article/123`
3. **Expected**: App opens, loading indicator, article detail screen

### Scenario 3: Invalid Article
1. Click: `https://beritabola.app/article/999999`
2. **Expected**: App opens, error chip "Article not found", navigate to home

### Scenario 4: External Content
1. Click: `https://beritabola.app/some-external-page`
2. **Expected**: Opens in external browser

### Scenario 5: Custom Scheme
1. Click: `beritabola://article/123`
2. **Expected**: Same behavior as https:// link

---

## 📲 OneSignal Integration

Deep links work seamlessly with OneSignal push notifications.

### Notification Payload Example
```json
{
  "app_id": "your_onesignal_app_id",
  "headings": {"en": "Breaking News: Messi Scores!"},
  "contents": {"en": "Read the full story..."},
  "url": "https://beritabola.app/article/12345",
  "data": {
    "type": "article",
    "articleId": "12345"
  }
}
```

### Handling in App
When user taps notification:
1. OneSignal delivers the `url` to DeepLinkService
2. DeepLinkService parses the URL
3. App navigates to article detail
4. User sees loading → article content

**For ads**: Use external URLs and they'll open in browser automatically.

---

## 🚀 Production Checklist

Before releasing to Google Play Store:

- [ ] **Generate Release Keystore**
  ```bash
  keytool -genkeypair -v -keystore beritabola-release.keystore -alias beritabola -keyalg RSA -keysize 2048 -validity 10000
  ```

- [ ] **Get Release SHA-256 Fingerprint**
  ```bash
  keytool -list -v -keystore beritabola-release.keystore -alias beritabola
  ```

- [ ] **Update assetlinks.json** with release fingerprint
  ```json
  {
    "sha256_cert_fingerprints": [
      "DEBUG_FINGERPRINT",
      "RELEASE_FINGERPRINT"
    ]
  }
  ```

- [ ] **Upload to production server**
  - Ensure HTTPS is working
  - Test URL accessibility
  - Verify Content-Type header

- [ ] **Update key.properties** for release signing
  ```properties
  storeFile=beritabola-release.keystore
  storePassword=YOUR_STORE_PASSWORD
  keyAlias=beritabola
  keyPassword=YOUR_KEY_PASSWORD
  ```

- [ ] **Build release APK/AAB**
  ```bash
  flutter build appbundle --release
  ```

- [ ] **Test deep links on release build**
  ```bash
  adb install build/app/outputs/bundle/release/app-release.aab
  adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/123" com.idnkt78.beritabola
  ```

---

## 🐛 Troubleshooting

### Issue: App Links Not Working
**Solution**:
1. Verify `assetlinks.json` is accessible at `/.well-known/assetlinks.json`
2. Check SHA-256 fingerprint matches your keystore
3. Ensure `android:autoVerify="true"` is in AndroidManifest.xml
4. Clear app data and reinstall

### Issue: Custom Scheme Not Working
**Solution**:
1. Check intent filter for `beritabola://` scheme in AndroidManifest.xml
2. Ensure app is installed
3. Test with ADB command

### Issue: "Article Not Found" Error
**Solution**:
1. Verify article ID is valid
2. Check WordPress API is accessible
3. Check network connection
4. Review logs for API errors

### Issue: Deep Link Opens Browser Instead of App
**Solution**:
1. Verify domain ownership (assetlinks.json)
2. Clear default browser settings in Android
3. Reinstall app
4. Use custom scheme as fallback

---

## 📝 Code Reference

### Key Files
- **Config**: `lib/config/deep_link_config.dart`
- **Service**: `lib/services/deep_link_service.dart`
- **Main**: `lib/main.dart` (initialization)
- **Manifest**: `android/app/src/main/AndroidManifest.xml`

### Deep Link Flow
```
1. User clicks link
   ↓
2. Android system receives intent
   ↓
3. App opens (MainActivity)
   ↓
4. DeepLinkService.initialize() listens
   ↓
5. Parse URI → Extract type & ID
   ↓
6. Fetch article from WordPress
   ↓
7. Navigate to ArticleDetailScreen
```

### Adding New Deep Link Types
```dart
// 1. Add pattern to deep_link_config.dart
static const String matchPattern = '/match/';

// 2. Add extraction method
static String? extractMatchId(String path) {
  final match = RegExp(r'/match/(\d+)').firstMatch(path);
  return match?.group(1);
}

// 3. Update parseDeepLink() in deep_link_service.dart
if (path.contains(DeepLinkConfig.matchPattern)) {
  final matchId = DeepLinkConfig.extractMatchId(path);
  return DeepLinkData(
    type: DeepLinkType.match,
    id: matchId,
    originalUri: uri,
  );
}

// 4. Handle in _routeDeepLink()
case DeepLinkType.match:
  _navigateToMatch(context, deepLinkData.id!);
  break;
```

---

## 📊 Analytics Integration (Future)

Track deep link performance:
```dart
// In DeepLinkService._handleDeepLink()
FirebaseAnalytics.instance.logEvent(
  name: 'deep_link_opened',
  parameters: {
    'link_type': deepLinkData.type.toString(),
    'link_id': deepLinkData.id ?? 'unknown',
    'source': 'notification', // or 'share', 'browser', etc.
  },
);
```

---

## ✅ Summary

- ✅ Deep links implemented for articles
- ✅ Both App Links and Custom Scheme supported
- ✅ Error handling with user-friendly messages
- ✅ Authentication flow integrated
- ✅ OneSignal notification ready
- ⏳ Domain verification pending (upload assetlinks.json)
- ⏳ Production keystore pending (before Play Store release)

---

**Last Updated**: November 19, 2025
**Status**: Ready for Testing
**Next Steps**: 
1. Upload `assetlinks.json` to `https://beritabola.app/.well-known/`
2. Test deep links with ADB
3. Integrate with OneSignal notifications
4. Generate production keystore before release
