# 🎨 Icon Setup Guide - Berita Bola

## 📱 Icon.Kitchen Output Analysis

✅ **What's Included:**
- Launcher icons (mipmap) for all densities
- Adaptive icons (Android 8.0+)
- Play Store icon (512x512)
- iOS icons
- Web icons

❌ **What's Missing:**
- **OneSignal notification small icon** (drawable resources)

---

## 🔔 OneSignal Small Icon Requirements

OneSignal requires **separate notification icons** that are:
- **Monochrome/Silhouette style** (white icon on transparent background)
- **Stored in drawable folders** (not mipmap)
- **Different sizes for different densities**

### Required Icon Sizes:
```
drawable-mdpi/    → 24x24 px
drawable-hdpi/    → 36x36 px
drawable-xhdpi/   → 48x48 px
drawable-xxhdpi/  → 72x72 px
drawable-xxxhdpi/ → 96x96 px
```

---

## 📂 Current Folder Structure

### ✅ Created Folders:
```
android/app/src/main/res/
├── drawable-mdpi/      # Ready for 24x24 notification icon
├── drawable-hdpi/      # Ready for 36x36 notification icon
├── drawable-xhdpi/     # Ready for 48x48 notification icon
├── drawable-xxhdpi/    # Ready for 72x72 notification icon
└── drawable-xxxhdpi/   # Ready for 96x96 notification icon
```

---

## 🛠️ Setup Instructions

### Step 1: Copy Launcher Icons
Copy launcher icons from icon.kitchen to your project:

```powershell
# Copy all mipmap folders to Android
Copy-Item -Path "assets\IconKitchen-Output\android\res\mipmap-*" -Destination "android\app\src\main\res\" -Recurse -Force

# Copy Play Store icon (for Google Play Console)
Copy-Item -Path "assets\IconKitchen-Output\android\play_store_512.png" -Destination "assets\launcher\" -Force
```

### Step 2: Create OneSignal Notification Icon

**Option A: Use Online Tool (Recommended)**
1. Go to: https://romannurik.github.io/AndroidAssetStudio/icons-notification.html
2. Upload your logo (preferably simple/silhouette version)
3. Set:
   - **Name**: `ic_onesignal_notification` or `ic_stat_onesignal_default`
   - **Style**: Simple (monochrome)
   - **Trim**: Yes
4. Download and extract to `android/app/src/main/res/`

**Option B: Use Your Logo in Photoshop/Figma**
1. Create a **white silhouette** version of your logo on transparent background
2. Export these sizes:
   - 24x24px → Save as `ic_stat_onesignal_default.png` in `drawable-mdpi`
   - 36x36px → Save in `drawable-hdpi`
   - 48x48px → Save in `drawable-xhdpi`
   - 72x72px → Save in `drawable-xxhdpi`
   - 96x96px → Save in `drawable-xxxhdpi`

**Option C: Use Football Icon (Simple)**
If you don't have a custom icon ready, use a simple football icon:
- Search "football silhouette icon png white transparent"
- Resize to required dimensions
- Name: `ic_stat_onesignal_default.png`

---

## 🔧 AndroidManifest.xml Configuration

Add this to `android/app/src/main/AndroidManifest.xml` inside `<application>` tag:

```xml
<!-- OneSignal Notification Icons -->
<meta-data
    android:name="com.onesignal.NotificationOpened.DEFAULT"
    android:value="DISABLED" />
<meta-data
    android:name="com.onesignal.small_icon"
    android:resource="@drawable/ic_stat_onesignal_default" />
<meta-data
    android:name="com.onesignal.large_icon"
    android:resource="@mipmap/ic_launcher" />
```

---

## 📋 Checklist

### Launcher Icons (icon.kitchen)
- [ ] Copy mipmap folders to `android/app/src/main/res/`
- [ ] Verify `ic_launcher.png` exists in all mipmap-* folders
- [ ] Copy `play_store_512.png` to `assets/launcher/`

### OneSignal Notification Icon
- [ ] Create white silhouette icon (24x24 to 96x96)
- [ ] Name it `ic_stat_onesignal_default.png`
- [ ] Place in all drawable-* folders
- [ ] Add meta-data to AndroidManifest.xml

### iOS Icons (if targeting iOS)
- [ ] Copy iOS icons from `assets/IconKitchen-Output/ios/`
- [ ] Update `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Test
- [ ] Run app and check launcher icon appears correctly
- [ ] Send test notification from OneSignal
- [ ] Verify notification shows custom icon (not bell)

---

## 🎨 Design Guidelines

### Launcher Icon
- **Style**: Can be colorful, detailed
- **Size**: Provided by icon.kitchen (all sizes)
- **Location**: mipmap folders

### Notification Small Icon
- **Style**: Monochrome (white on transparent)
- **Rule**: Must be simple silhouette
- **Android Requirement**: No gradients, no colors (will be tinted by system)
- **Location**: drawable folders

---

## 🔍 Verification Commands

```powershell
# Check if launcher icons exist
Get-ChildItem -Path "android\app\src\main\res\mipmap-*" -Recurse -Filter "ic_launcher.png"

# Check if notification icons exist
Get-ChildItem -Path "android\app\src\main\res\drawable-*" -Recurse -Filter "ic_stat_onesignal_default.png"

# Count icons (should be 5 for each type)
(Get-ChildItem -Path "android\app\src\main\res\drawable-*" -Filter "ic_stat_onesignal_default.png").Count
```

---

## 📱 Expected Result

### Before Notification:
- App shows custom launcher icon (from icon.kitchen)
- App name: Berita Bola

### When Notification Arrives:
- ✅ Small icon: Your custom football/logo icon (white)
- ✅ Large icon: Full color launcher icon
- ✅ Title: "Berita Bola" or custom title
- ✅ Message: Your notification text

---

## 🚨 Common Issues

### Issue: Notification shows bell icon
**Cause**: Missing notification icon in drawable folders
**Fix**: Create and place `ic_stat_onesignal_default.png` in all drawable-* folders

### Issue: Notification icon is colored/looks wrong
**Cause**: Icon has colors or gradients
**Fix**: Use pure white (#FFFFFF) silhouette on transparent background

### Issue: Icon is too small/large in notification
**Cause**: Wrong dimensions for density
**Fix**: Use exact sizes: 24, 36, 48, 72, 96 px

---

## 📞 Quick Commands

### Copy Launcher Icons from icon.kitchen
```powershell
# Navigate to project root
cd c:\Users\User\OneDrive\Documents\Tito_script\beritabola\beritabolav1

# Copy mipmap folders
Copy-Item -Path "assets\IconKitchen-Output\android\res\mipmap-*" -Destination "android\app\src\main\res\" -Recurse -Force
```

### Create Placeholder Notification Icon (Temporary)
If you need to test immediately, you can use Flutter's default temporarily, but **must replace** with custom icon before release.

---

**Created**: November 17, 2025
**Status**: Ready for icon upload
