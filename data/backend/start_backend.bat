@echo off
echo 🚀 Starting Brightify Dart Backend...
echo.
echo 📍 Location: brightify_mobile/data/backend/
echo 📡 MQTT: HiveMQ Cloud (brightify-mqtt)
echo 🔥 Firebase: brightify-2c720
echo.

cd /d "%~dp0"

echo 🔍 Checking dependencies...
dart pub get

echo.
echo 🚀 Starting server on http://localhost:8080...
echo 📱 Mobile app will discover this backend automatically
echo.
echo Press Ctrl+C to stop the server
echo =====================================

dart run bin/main.dart

pause
