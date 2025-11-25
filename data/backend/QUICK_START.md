# 🚀 QUICK START - Dart Backend

## ⚡ **FIXED COMMANDS**

### **1. Start Server (PowerShell):**
```powershell
# Option 1: Using batch file (PowerShell)
.\start_server.bat

# Option 2: Direct dart command
dart run bin/main.dart

# Option 3: Using pub run
dart pub run
```

### **2. Start Server (Command Prompt):**
```cmd
# Option 1: Using batch file
start_server.bat

# Option 2: Direct dart command  
dart run bin/main.dart
```

---

## 🔧 **TROUBLESHOOTING**

### **Error: "start_server.bat not recognized"**
**Solution**: Use `.\start_server.bat` in PowerShell

### **Error: "Could not find bin\brightify_dart_backend.dart"**
**Solution**: Use `dart run bin/main.dart` instead of `dart run`

---

## ✅ **WORKING COMMANDS**

```powershell
# Navigate to backend folder
cd "D:\KEJURUAN SMT 5\React\BrigtifyPack\brightify_dart_backend"

# Install dependencies
dart pub get

# Configure environment
copy .env.example .env
# Edit .env file with your configuration

# Start server (choose one)
dart run bin/main.dart
# OR
.\start_server.bat
```

---

## 🎯 **EXPECTED OUTPUT**

When successful, you should see:
```
🔥 Initializing Firebase Admin...
📡 Initializing MQTT Service...
✅ Firebase Admin initialized successfully
✅ MQTT Connected successfully
🚀 Brightify Dart Backend running on http://0.0.0.0:8080
📱 Mobile apps can connect to: http://localhost:8080
```

---

## 🌐 **TEST BACKEND**

Open browser: http://localhost:8080/health

Expected response:
```json
{
  "status": "healthy",
  "service": "Brightify Dart Backend"
}
```
