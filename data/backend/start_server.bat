@echo off
echo 🚀 Starting Brightify Dart Backend...
echo.

REM Check if .env exists
if not exist ".env" (
    echo ❌ .env file not found!
    echo Please copy .env.example to .env and configure it.
    echo.
    pause
    exit /b 1
)

REM Install dependencies
echo 📦 Installing dependencies...
dart pub get

if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo ✅ Dependencies installed successfully
echo.

REM Get local IP address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set "ip=%%a"
    goto :found
)
:found
set ip=%ip: =%

echo 🌐 Server will be available at:
echo   - Local: http://localhost:8080
echo   - Network: http://%ip%:8080
echo.
echo 📱 Update your mobile app to use one of these URLs
echo.
echo 🔥 Starting server...
echo Press Ctrl+C to stop
echo.

REM Start the server
dart run bin/main.dart

pause
