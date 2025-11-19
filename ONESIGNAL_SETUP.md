# 🔔 OneSignal Push Notifications - Setup & Usage Guide

**Status**: ✅ Fully Implemented  
**Last Updated**: November 19, 2025

---

## 📋 Implementation Summary

OneSignal push notifications have been fully integrated into Berita Bola. The system supports:

✅ **Notification Types**:
- New article notifications
- Match update notifications  
- Comment reply notifications (future)

✅ **User Management**:
- External user ID syncing (Firebase UID → OneSignal)
- Notification preferences (enable/disable)
- Automatic user tagging for segmentation

✅ **Deep Link Integration**:
- Article notifications → Open article detail
- Match notifications → Open match detail (when implemented)
- Custom URL handling

✅ **UI/UX**:
- Notification toggle in Profile page
- Only visible to authenticated users (not anonymous)
- Preference synced with Firestore

---

## 🚀 Setup Instructions

### Step 1: Create OneSignal Account

1. Go to [OneSignal](https://onesignal.com/)
2. Sign up for a free account
3. Create a new app: **Berita Bola**
4. Select platform: **Android**

### Step 2: Configure Android App

1. In OneSignal dashboard, go to **Settings** → **Platforms** → **Google Android (FCM)**
2. Click **Configure**
3. You'll need:
   - **Firebase Server Key** (from Firebase Console)
   - **Firebase Sender ID** (from Firebase Console)

#### Get Firebase Credentials:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **beritabola-8bccc**
3. Go to **Project Settings** (gear icon) → **Cloud Messaging**
4. Copy:
   - **Server Key**
   - **Sender ID**
5. Paste into OneSignal

### Step 3: Update App ID

1. Get your OneSignal App ID from dashboard (top-left, under app name)
2. Open `lib/services/onesignal_service.dart`
3. Replace the placeholder:

```dart
// Line 19
static const String _appId = 'YOUR_ONESIGNAL_APP_ID';
```

**Example**:
```dart
static const String _appId = '12345678-abcd-1234-efgh-123456789012';
```

### Step 4: Update Android Configuration

#### 4.1 Add OneSignal Gradle Plugin

Open `android/build.gradle.kts` and add:

```kotlin
plugins {
    // ... existing plugins
    id("com.onesignal.androidsdk.onesignal-gradle-plugin") version "0.17.6" apply false
}
```

#### 4.2 Apply Plugin in App Module

Open `android/app/build.gradle.kts` and add at the top:

```kotlin
plugins {
    // ... existing plugins
    id("com.onesignal.androidsdk.onesignal-gradle-plugin")
}
```

### Step 5: Run Flutter Pub Get

```bash
flutter pub get
```

### Step 6: Test Notification

1. Run the app on a physical device (emulator might not receive notifications properly)
2. Login with a real account (not anonymous)
3. Go to Profile → Enable "Notifikasi Push"
4. In OneSignal dashboard:
   - Go to **Messages** → **New Push**
   - Select your app
   - Write a test message
   - Click **Send to Test Device** or **Send to All Subscribed Users**

---

## 📱 How It Works

### User Flow

```
1. User opens app → OneSignal initializes
2. User logs in → External user ID set (Firebase UID)
3. User goes to Profile → Toggle notification (ON/OFF)
4. Preference saved to Firestore
5. OneSignal subscribes/unsubscribes user
```

### Notification Click Flow

```
User taps notification
     ↓
OneSignal click handler triggered
     ↓
Check notification data (additionalData)
     ↓
Extract URL or article_id
     ↓
Deep Link Service handles navigation
     ↓
User sees content
```

---

## 🎯 Sending Notifications

### Method 1: OneSignal Dashboard (Manual)

1. Go to **Messages** → **New Push**
2. Fill in:
   - **Title**: Berita Terbaru!
   - **Message**: Ronaldo kembali ke Manchester United
   - **Launch URL**: `https://beritabola.app/article/123` (optional)
3. **Additional Data** (for deep linking):
   ```json
   {
     "url": "https://beritabola.app/article/123"
   }
   ```
   OR
   ```json
   {
     "article_id": "123"
   }
   ```
4. Click **Send**

### Method 2: OneSignal API (Automated)

#### Send to All Users:

```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "included_segments": ["Subscribed Users"],
    "headings": {"en": "Berita Terbaru!"},
    "contents": {"en": "Ronaldo kembali ke Manchester United"},
    "data": {
      "article_id": "123",
      "url": "https://beritabola.app/article/123"
    }
  }'
```

#### Send to Specific User:

```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "YOUR_APP_ID",
    "include_external_user_ids": ["firebase_user_uid_here"],
    "headings": {"en": "Ada balasan untuk komentar Anda"},
    "contents": {"en": "John Doe membalas komentar Anda"},
    "data": {
      "url": "https://beritabola.app/article/123#comment-456"
    }
  }'
```

---

## 🏷️ User Segmentation with Tags

OneSignal allows you to segment users with tags. Example use cases:

### Set Tags (in code):

```dart
// When user follows a team
await OneSignalService().setTags({
  'favorite_team': 'Manchester United',
  'language': 'id',
  'user_type': 'premium'
});
```

### Send to Segment:

```json
{
  "app_id": "YOUR_APP_ID",
  "filters": [
    {"field": "tag", "key": "favorite_team", "relation": "=", "value": "Manchester United"}
  ],
  "headings": {"en": "Manchester United Menang!"},
  "contents": {"en": "United mengalahkan Liverpool 3-0"}
}
```

---

## 🧪 Testing Checklist

### Before Production:

- [ ] Test notification on physical Android device
- [ ] Test deep link navigation (article)
- [ ] Test notification toggle (enable/disable)
- [ ] Verify Firestore sync
- [ ] Test anonymous user (should not receive notifications)
- [ ] Test logout (OneSignal external user ID removed)
- [ ] Test login (OneSignal external user ID set)
- [ ] Test notification foreground/background/killed app states

### Production Ready:

- [ ] Replace `YOUR_ONESIGNAL_APP_ID` with actual App ID
- [ ] Verify Firebase Server Key is correct
- [ ] Set up production notification templates in OneSignal
- [ ] Configure notification icons (see below)
- [ ] Test on multiple devices and Android versions

---

## 🎨 Custom Notification Icon (Optional)

To use a custom icon for notifications:

### Step 1: Create Icon

1. Create a white transparent PNG (96x96px)
2. Name it `ic_stat_onesignal_default.png`
3. Use [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-notification.html)

### Step 2: Add to Project

Place in:
```
android/app/src/main/res/
  ├── drawable-mdpi/ic_stat_onesignal_default.png (24x24)
  ├── drawable-hdpi/ic_stat_onesignal_default.png (36x36)
  ├── drawable-xhdpi/ic_stat_onesignal_default.png (48x48)
  ├── drawable-xxhdpi/ic_stat_onesignal_default.png (72x72)
  └── drawable-xxxhdpi/ic_stat_onesignal_default.png (96x96)
```

---

## 📊 Analytics & Monitoring

### OneSignal Dashboard Metrics:

- **Delivery Rate**: How many notifications were delivered
- **Open Rate**: How many users tapped the notification
- **Click-through Rate**: Percentage of delivered notifications that were opened
- **Outcomes**: Track actions taken after opening (if configured)

### View Analytics:

1. OneSignal Dashboard → **Analytics**
2. Filter by:
   - Date range
   - Notification type
   - User segment

---

## 🔒 Privacy & Permissions

### Android Permissions (Already Added):

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS (Future):

When iOS support is added, update:
- `ios/Runner/Info.plist`
- Request notification permission explicitly

---

## 🐛 Troubleshooting

### Issue: Notifications not received

**Solutions**:
1. Check OneSignal App ID is correct
2. Verify Firebase Server Key in OneSignal
3. Ensure device has internet connection
4. Check if notifications are enabled in device settings
5. Use physical device (emulator may not work)
6. Check OneSignal dashboard for delivery status

### Issue: Deep links not working

**Solutions**:
1. Verify `additionalData` format in notification
2. Check deep link service is initialized
3. Test deep link manually first: `adb shell am start -W -a android.intent.action.VIEW -d "URL"`
4. Check logs for deep link errors

### Issue: External user ID not set

**Solutions**:
1. User must be authenticated (not anonymous)
2. Check `authService.currentUser` is not null
3. Verify OneSignal initialization completed
4. Check logs for OneSignal errors

### Issue: Notification toggle not working

**Solutions**:
1. User must be logged in (not anonymous)
2. Check internet connection
3. Verify Firestore permissions
4. Check OneSignal initialization status

---

## 🚀 Production Checklist

Before going live:

1. **OneSignal Setup**:
   - [ ] App ID updated in code
   - [ ] Firebase credentials configured
   - [ ] Test notifications sent successfully

2. **Deep Links**:
   - [ ] Article deep links working
   - [ ] Match deep links ready (when feature complete)
   - [ ] Error handling tested

3. **User Experience**:
   - [ ] Notification toggle visible and working
   - [ ] Anonymous users excluded
   - [ ] Logout properly removes user ID
   - [ ] Login properly sets user ID

4. **Testing**:
   - [ ] Tested on multiple Android versions
   - [ ] Tested foreground/background/killed states
   - [ ] Tested deep link navigation
   - [ ] Tested notification preferences

5. **Monitoring**:
   - [ ] OneSignal analytics configured
   - [ ] Notification delivery monitored
   - [ ] User engagement tracked

---

## 📚 Additional Resources

- **OneSignal Docs**: https://documentation.onesignal.com/docs/flutter-sdk-setup
- **OneSignal API**: https://documentation.onesignal.com/reference
- **Flutter Plugin**: https://pub.dev/packages/onesignal_flutter
- **Firebase Cloud Messaging**: https://firebase.google.com/docs/cloud-messaging

---

## 🎯 Next Steps (Optional Enhancements)

1. **Rich Notifications**:
   - Add images to notifications
   - Add action buttons (Read, Share, etc.)

2. **Advanced Segmentation**:
   - Segment by favorite teams
   - Segment by reading habits
   - Segment by location

3. **In-App Messages**:
   - Welcome messages for new users
   - Feature announcements
   - Engagement prompts

4. **Notification Scheduling**:
   - Schedule match notifications before kickoff
   - Daily news digest
   - Weekly highlights

---

**🎉 OneSignal is ready to use! Complete setup Step 3 (App ID) to start sending notifications.**
