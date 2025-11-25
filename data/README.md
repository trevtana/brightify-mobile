# 📁 Brightify Mobile - Data Folder

Folder ini berisi semua komponen backend dan testing untuk aplikasi Brightify Mobile.

## 📂 Struktur Folder

```
data/
├── backend/                    # Dart Backend Server
│   ├── lib/                   # Backend source code
│   ├── bin/                   # Entry point (main.dart)
│   ├── .env                   # Environment variables
│   ├── pubspec.yaml          # Backend dependencies
│   └── start_backend.bat     # Quick start script
├── test_mobile_logic.dart     # Mobile app logic testing
├── test_mqtt.dart            # MQTT connection testing
└── test_web.html             # Web interface for testing
```

## 🚀 Quick Start

### 1. Start Backend Server
```bash
cd data/backend
dart run bin/main.dart
```

Atau gunakan script:
```bash
cd data/backend
./start_backend.bat
```

### 2. Run Mobile App
```bash
# Dari root folder brightify_mobile
flutter run -d <device_id>
```

### 3. Testing
```bash
# Test mobile logic
cd data
dart run test_mobile_logic.dart

# Test MQTT
dart run test_mqtt.dart

# Web testing - buka test_web.html di browser
```

## 🔧 Konfigurasi

### Backend Discovery
Mobile app akan otomatis mencari backend di:
- `http://10.219.238.190:8080` (PC IP - primary)
- `http://localhost:8080` (untuk emulator)
- IP addresses lainnya (lihat `lib/services/backend_discovery.dart`)

### Environment Variables
Backend menggunakan file `.env` di `data/backend/.env`:
- Firebase configuration
- HiveMQ MQTT credentials
- Server settings

## 📡 Endpoints

### Backend API
- `GET /health` - Health check
- `POST /api/v1/devices/{chipId}/control` - Device control (with auth)
- `POST /test/v1/devices/{chipId}/test` - Device control (no auth, for testing)

### MQTT Topics
- `brightify/devices/{chipId}/power`
- `brightify/devices/{chipId}/brightness`
- `brightify/devices/{chipId}/color`
- `brightify/devices/{chipId}/control`

## 🧪 Testing

1. **Backend Health**: `http://localhost:8080/health`
2. **MQTT Connection**: Menggunakan HiveMQ Cloud
3. **Device Control**: Via REST API atau web interface
4. **Mobile Logic**: Test tanpa Flutter build

## 📱 Mobile App Integration

Mobile app akan:
1. **Discover Backend** - Otomatis mencari backend server
2. **Authenticate** - Menggunakan Firebase ID token
3. **Control Devices** - Via REST API ke backend
4. **Real-time Updates** - Via WebSocket connection

## 🔍 Troubleshooting

### Backend tidak ditemukan
- Pastikan backend running di port 8080
- Cek IP address di `backend_discovery.dart`
- Test manual: `curl http://localhost:8080/health`

### MQTT tidak connect
- Cek credentials di `.env`
- Verify HiveMQ Cloud cluster aktif
- Test dengan `dart run test_mqtt.dart`

### Flutter build error
- `flutter clean && flutter pub get`
- Cek Android SDK configuration
- Try `flutter doctor -v`
