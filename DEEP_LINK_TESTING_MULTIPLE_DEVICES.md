# Deep Link Test Commands - Multiple Devices

## List Connected Devices
```powershell
adb devices
```

## Test on Physical Device (22120RN86G)
```powershell
adb -s 8dzxqg9h5xwotsx4 shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/582" com.idnkt78.beritabola
```

## Test on Emulator (sdk gphone64 x86 64)
```powershell
adb -s emulator-5554 shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/582" com.idnkt78.beritabola
```

## Test Custom Scheme on Physical Device
```powershell
adb -s 8dzxqg9h5xwotsx4 shell am start -W -a android.intent.action.VIEW -d "beritabola://article/582" com.idnkt78.beritabola
```

## Test Custom Scheme on Emulator
```powershell
adb -s emulator-5554 shell am start -W -a android.intent.action.VIEW -d "beritabola://article/582" com.idnkt78.beritabola
```

## Quick Test Commands

### Physical Device (Quick Copy-Paste)
```powershell
# Article 582
adb -s 8dzxqg9h5xwotsx4 shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/582" com.idnkt78.beritabola

# Test invalid article
adb -s 8dzxqg9h5xwotsx4 shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/999999" com.idnkt78.beritabola
```

### Emulator (Quick Copy-Paste)
```powershell
# Article 582
adb -s emulator-5554 shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/582" com.idnkt78.beritabola

# Test invalid article
adb -s emulator-5554 shell am start -W -a android.intent.action.VIEW -d "https://beritabola.app/article/999999" com.idnkt78.beritabola
```

## View Logs for Specific Device

### Physical Device Logs
```powershell
adb -s 8dzxqg9h5xwotsx4 logcat | Select-String "deep|📎|❌|✅"
```

### Emulator Logs
```powershell
adb -s emulator-5554 logcat | Select-String "deep|📎|❌|✅"
```

## Install App on Specific Device

### Install on Physical Device
```powershell
flutter install -d 8dzxqg9h5xwotsx4
```

### Install on Emulator
```powershell
flutter install -d emulator-5554
```

## Clear App Data (If Issues)

### Clear on Physical Device
```powershell
adb -s 8dzxqg9h5xwotsx4 shell pm clear com.idnkt78.beritabola
```

### Clear on Emulator
```powershell
adb -s emulator-5554 shell pm clear com.idnkt78.beritabola
```
