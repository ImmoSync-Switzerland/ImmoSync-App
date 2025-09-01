@echo off
echo Starting APK crash logging...
echo.
echo Make sure your Android device is connected via USB with USB Debugging enabled
echo.
pause

echo Clearing previous logs...
C:\Users\fabud\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat -c

echo.
echo Installing APK...
C:\Users\fabud\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-release.apk

echo.
echo Starting logcat capture...
echo Try to launch the app now. Press Ctrl+C to stop logging.
echo.
C:\Users\fabud\AppData\Local\Android\Sdk\platform-tools\adb.exe logcat -v time | findstr /i "FATAL ERROR CRASH EXCEPTION ImmoSync flutter"
