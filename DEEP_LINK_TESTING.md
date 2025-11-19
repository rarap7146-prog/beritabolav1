# Deep Link Test Commands

## Prerequisites
- Android device/emulator connected
- App installed: com.idnkt78.beritabola
- ADB (Android Debug Bridge) installed

## Test Commands

### 1. Test Article Deep Link (https)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/123" com.idnkt78.beritabola
```

### 2. Test Article Deep Link (Custom Scheme)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "beritabola://article/123" com.idnkt78.beritabola
```

### 3. Test Post Pattern
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/post/456" com.idnkt78.beritabola
```

### 4. Test Direct ID Pattern
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/789" com.idnkt78.beritabola
```

### 5. Test Invalid Article (Error Handling)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/999999" com.idnkt78.beritabola
```

### 6. Test Category (Future Feature)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/category/liga-inggris" com.idnkt78.beritabola
```

### 7. Test Unknown Path (Should Open Browser)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/some-random-page" com.idnkt78.beritabola
```

## PowerShell Commands (Windows)

### Test Article Link
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/123" com.idnkt78.beritabola
```

### Test Custom Scheme
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "beritabola://article/123" com.idnkt78.beritabola
```

## Expected Results

### Success Case (Valid Article)
1. App launches/comes to foreground
2. Loading indicator appears
3. Article detail screen loads
4. Article content displayed

### Error Case (Invalid Article)
1. App launches/comes to foreground
2. Loading indicator appears briefly
3. Error chip displayed: "Article not found"
4. App navigates to home screen

### Browser Case (Unknown Content)
1. External browser opens
2. URL loads in browser

## Verification Checklist

- [ ] App opens on article link click
- [ ] Loading indicator shows while fetching
- [ ] Article content loads correctly
- [ ] Error message shows for invalid articles
- [ ] Home screen loads after error
- [ ] Custom scheme works (beritabola://)
- [ ] App Links work (https://beritabola.app)
- [ ] Unknown URLs open in browser
- [ ] Works when app is closed
- [ ] Works when app is in background
- [ ] Works for anonymous users
- [ ] Works for logged-in users

## Logcat Debugging

### View Deep Link Logs
```bash
adb logcat | findstr "deep"
```

### View All App Logs
```bash
adb logcat | findstr "com.idnkt78.beritabola"
```

### Clear Logcat
```bash
adb logcat -c
```

## Troubleshooting

### App Doesn't Open
- Check if app is installed: `adb shell pm list packages | findstr beritabola`
- Reinstall app: `flutter install`
- Clear app data: `adb shell pm clear com.idnkt78.beritabola`

### Browser Opens Instead of App
- Upload assetlinks.json to server
- Clear default browser association
- Use custom scheme instead

### Error: "Activity not started"
- Check package name is correct
- Verify intent filter in AndroidManifest.xml
- Check ADB connection: `adb devices`
