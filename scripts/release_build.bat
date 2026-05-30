@echo off

echo ====================================
echo BABY CORN RELEASE BUILD
echo ====================================

echo.
echo [1/7] Stopping Gradle...
cd android
call gradlew.bat --stop
cd ..

echo.
echo [2/7] Cleaning project...
call flutter clean

echo.
echo [3/7] Fetching dependencies...
call flutter pub get

echo.
echo [4/7] Building APK (for local testing)...
call flutter build apk --release

echo.
echo [5/7] Building App Bundle (for Play Store)...
call flutter build appbundle --release

echo.
echo [6/7] Build completed.
echo.

echo Outputs:
echo APK (Local Test): build\app\outputs\flutter-apk\app-release.apk
echo AAB (Play Store): build\app\outputs\bundle\release\app-release.aab

echo ====================================
echo [7/7] To install the APK on your connected device, run:
echo flutter install
echo ====================================

pause