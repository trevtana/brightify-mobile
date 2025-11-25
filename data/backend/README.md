# 🚀 Brightify Dart Backend

Native Dart backend server untuk Brightify mobile app. Menggantikan dependency pada Node.js backend dan NGROK.

## ✨ Features

- 🔥 **Firebase Admin Integration** - Direct Firebase access
- 📡 **MQTT Client** - HiveMQ Cloud integration  
- 🔐 **JWT Authentication** - Firebase token verification
- 🌐 **REST API** - Device control endpoints
- ⚡ **High Performance** - Native Dart server
- 🔧 **Zero Configuration** - Auto-discovery backend

## 🛠️ Setup

### 1. Install Dependencies
```bash
cd brightify_dart_backend
dart pub get
```

### 2. Environment Configuration
Copy `.env.example` to `.env` dan isi dengan konfigurasi Anda:

```bash
cp .env.example .env
```

Edit `.env`:
```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-brightify-project
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id

# MQTT Configuration (HiveMQ Cloud)
MQTT_BROKER=60258db0be014a6082b916c7725bf6dd.s1.eu.hivemq.cloud
MQTT_PORT=8883
MQTT_USERNAME=your-hivemq-username
MQTT_PASSWORD=your-hivemq-password
MQTT_USE_SSL=true

# Server Configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
```

### 3. Firebase Service Account
1. Go to Firebase Console → Project Settings → Service Accounts
2. Generate new private key
3. Copy values to `.env` file

### 4. Run Server
```bash
dart run
```

Server akan berjalan di:
- **Local**: http://localhost:8080
- **Network**: http://YOUR_IP:8080

## 📱 Mobile App Integration

Update mobile app untuk menggunakan backend Dart:

```dart
// lib/services/backend_discovery.dart
class BackendDiscovery {
  static const List<String> endpoints = [
    'http://192.168.1.100:8080',  // Local network
    'http://localhost:8080',      // Localhost
  ];
  
  static Future<String?> findBackend() async {
    for (String endpoint in endpoints) {
      try {
        final response = await http.get(Uri.parse('$endpoint/health'));
        if (response.statusCode == 200) return endpoint;
      } catch (e) { continue; }
    }
    return null;
  }
}
```

## 🔌 API Endpoints

### Health Check
```http
GET /health
```

### Device Control
```http
POST /api/v1/devices/{chipId}/control
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "power": true,
  "brightness": 255,
  "red": 255,
  "green": 0,
  "blue": 0,
  "homeId": "home123",
  "roomId": "Kamar Arkan"
}
```

### Create Home
```http
POST /api/v1/homes
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "name": "Rumah Utama",
  "address": "Jl. Contoh No. 123",
  "country": "Indonesia"
}
```

### Create Room
```http
POST /api/v1/homes/{homeId}/rooms
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "room_name": "Kamar Tidur",
  "room_type": "bedroom"
}
```

### Add Device
```http
POST /api/v1/homes/{homeId}/rooms/{roomId}/devices
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "device_name": "Lampu LED Strip",
  "chip_id": "D92F2B14",
  "pairing_code": "123456",
  "device_type": "LED_STRIP"
}
```

## 🔧 Development

### Run in Development Mode
```bash
dart run --enable-vm-service
```

### Build Executable
```bash
dart compile exe bin/main.dart -o brightify_server
```

### Run Executable
```bash
./brightify_server
```

## 🚀 Deployment

### Option 1: Local Network
```bash
# Run on local network
dart run
```
Mobile apps di network yang sama bisa akses via IP.

### Option 2: VPS/Cloud
```bash
# Upload ke VPS
scp -r brightify_dart_backend user@your-vps:/opt/
ssh user@your-vps
cd /opt/brightify_dart_backend
dart pub get
dart run
```

### Option 3: Docker
```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o server

FROM scratch
COPY --from=build /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

## 🔍 Troubleshooting

### MQTT Connection Issues
```bash
# Check MQTT credentials
dart run lib/services/mqtt_service.dart
```

### Firebase Issues
```bash
# Verify service account
dart run lib/services/firebase_service.dart
```

### Port Issues
```bash
# Check if port 8080 is available
netstat -an | grep 8080

# Use different port
SERVER_PORT=3000 dart run
```

## 📊 Benefits vs Node.js Backend

| Aspect | Node.js + NGROK | Dart Native |
|--------|-----------------|-------------|
| **Setup** | Complex (NGROK config) | Simple (IP only) |
| **Performance** | Good | Excellent |
| **Memory** | ~100MB | ~20MB |
| **Dependencies** | Many (npm) | Few (pub) |
| **Maintenance** | High | Low |
| **Mobile Integration** | Manual URL update | Auto-discovery |

## 🎯 Next Steps

1. ✅ **Phase 1**: Backend Dart native (DONE)
2. 🔄 **Phase 2**: Update mobile app
3. 📱 **Phase 3**: Performance optimization
4. 💸 **Phase 4**: Firebase quota optimization

---

**🎉 Selamat! Backend Dart native sudah siap digunakan!**
