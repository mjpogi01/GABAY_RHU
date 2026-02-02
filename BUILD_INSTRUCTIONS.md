# GABAY - Build Instructions (Low Memory Systems)

Your system is hitting memory limits when building. Follow these steps **in order**:

## 1. Increase Windows Virtual Memory (Critical)

1. Press `Win + R`, type `sysdm.cpl`, Enter
2. **Advanced** tab → **Performance** → **Settings**
3. **Advanced** tab → **Virtual memory** → **Change**
4. Uncheck **Automatically manage paging file size**
5. Select your system drive (usually C:)
6. Choose **Custom size**:
   - **Initial size:** 4096 MB
   - **Maximum size:** 8192 MB (or higher if you have disk space)
7. Click **Set** → **OK** → **OK**
8. **Restart your computer** for changes to take effect

## 2. Free RAM Before Building

- **Close the Android emulator** (uses 1–2 GB RAM)
- Close Chrome, Edge, and other browsers
- Close Android Studio if not needed
- Close other heavy applications

## 3. Build the APK

```powershell
cd c:\Gabay
C:\flutter\bin\flutter.bat build apk --debug
```

The APK will be at: `build\app\outputs\flutter-apk\app-debug.apk`

## 4. Install & Run

**Option A – Physical phone (recommended)**
1. Enable USB debugging on your Android phone
2. Connect via USB
3. Run: `C:\flutter\bin\flutter.bat run`

**Option B – Emulator**
1. Start the emulator from Android Studio
2. Run: `C:\flutter\bin\flutter.bat run`

## 5. If Build Still Fails

Stop the Gradle daemon and retry:

```powershell
cd c:\Gabay\android
.\gradlew.bat --stop
cd ..
C:\flutter\bin\flutter.bat build apk --debug
```
