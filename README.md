# Brightify Mobile - Flutter App

Smart Home IoT Lighting Control - Mobile Application

## 🚀 Tech Stack

- **Flutter** (SDK 3.x)
- **Dart**
- **Firebase** (Auth, Firestore)
- **MQTT Client** for real-time device control
- **Provider** for state management
- **Flutter Colorpicker** for RGB control

## 📋 Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Firebase project

## 🔧 Installation

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/brightify-mobile.git
cd brightify-mobile
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Firebase

1. Download `google-services.json` (Android) from Firebase Console
2. Place it in `android/app/`
3. Download `GoogleService-Info.plist` (iOS) from Firebase Console
4. Place it in `ios/Runner/`

### 4. Configure environment variables

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` with your configuration.

## 🏃 Running the Application

### Android
```bash
flutter run
```

### iOS
```bash
flutter run -d ios
```

### Build APK
```bash
flutter build apk --release
```

## 📁 Project Structure

```
brightify_mobile/
├── lib/
│   ├── screens/        # UI screens
│   ├── services/       # Firebase & MQTT services
│   ├── models/         # Data models
│   └── main.dart
├── android/
├── ios/
└── pubspec.yaml
```

## ✨ Features

- 🔐 Firebase Authentication (Email & Google Sign-In)
- 💡 Real-time device control via MQTT
- 🎨 RGB color picker for smart lights
- 📊 Energy monitoring dashboard
- ⏰ Schedule automation
- 🏠 Multi-home & room management

## 🔐 Security Notes

- Never commit `.env` files
- Keep Firebase config files secure
- Use Firebase security rules

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 👤 Author

Arkan Ardiansyah - [trevtana](https://github.com/yourusername)

## 🔗 Related Repositories

- [Brightify Web](https://github.com/trevtana/brightify-web) - Web dashboard
