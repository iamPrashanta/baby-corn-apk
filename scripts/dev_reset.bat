@echo off

echo ====================================
echo BABY CORN QUICK RESET
echo ====================================

echo.
echo [1/6] Stopping Gradle...
cd android
call gradlew.bat --stop
cd ..

echo.
echo [2/6] Killing Java processes...
taskkill /F /IM java.exe /T >nul 2>&1

echo.
echo [3/6] Flutter clean...
call flutter clean

echo.
echo [4/6] Pub get...
call flutter pub get

echo.
echo [5/6] Ready for fresh run...
echo.

echo Recommended:
echo flutter run

echo OR
echo flutter build appbundle

echo ====================================

pause