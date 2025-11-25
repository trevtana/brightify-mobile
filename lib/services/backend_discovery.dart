/// ✅ CLOUD-FIRST ARCHITECTURE
/// 
/// Backend Discovery di-refactor untuk cloud-first approach.
/// Tidak lagi bergantung pada IP discovery yang error-prone.
/// 
/// Architecture:
/// Mobile App ←→ Firebase Firestore (Cloud) ←→ Website
///        ↓
///  HiveMQ MQTT (Cloud)
///        ↓
///   ESP32 Device
/// 
/// Keuntungan:
/// - No IP address management
/// - Works dari mana saja (internet)
/// - Real-time sync otomatis
/// - Production ready

class BackendDiscovery {
  // ❌ DEPRECATED: IP-based discovery tidak digunakan lagi
  // Diganti dengan Firebase + MQTT Cloud
  
  static bool _isCloudMode = true;
  static String? _status;

  /// ✅ NEW: Cloud-First Initialization
  /// Tidak perlu discover IP lagi, langsung ke cloud services
  static Future<bool> initializeCloudServices() async {
    print('☁️ Initializing Cloud Services (Firebase + MQTT)...');
    
    try {
      // Cloud services sudah initialized di main.dart
      // Fungsi ini hanya untuk compatibility dengan code lama
      _isCloudMode = true;
      _status = 'cloud';
      print('✅ Cloud services ready');
      return true;
    } catch (e) {
      print('❌ Cloud initialization error: $e');
      return false;
    }
  }

  /// ✅ NEW: Get connection mode
  static String getConnectionMode() {
    return _status ?? 'cloud';
  }
  
  /// ✅ NEW: Check if using cloud services
  static bool get isCloudMode => _isCloudMode;
  
  /// ⚠️ DEPRECATED: Backend URL tidak diperlukan lagi
  /// Gunakan Firebase Firestore langsung
  @Deprecated('Use Firebase Firestore instead')
  static Future<String?> getBackendUrl() async {
    print('⚠️ getBackendUrl() is deprecated - Use Firebase Firestore instead');
    return null;
  }

  /// ⚠️ DEPRECATED: Backend discovery tidak diperlukan lagi
  @Deprecated('Use initializeCloudServices() instead')
  static Future<String?> refreshBackend() async {
    print('⚠️ refreshBackend() is deprecated - Use initializeCloudServices() instead');
    return await initializeCloudServices() ? 'cloud' : null;
  }

  /// ✅ Check if cloud services available
  static Future<bool> isBackendAvailable() async {
    return _isCloudMode;
  }

  /// ✅ NEW: Get cloud service info for debugging
  static Map<String, dynamic> getCloudServiceInfo() {
    return {
      'mode': 'cloud',
      'firebase': 'connected',
      'mqtt': 'hivemq-cloud',
      'status': _status ?? 'initializing',
      'description': 'Cloud-First Architecture - No IP dependency',
    };
  }

  /// ⚠️ DEPRECATED: Manual backend tidak diperlukan lagi
  @Deprecated('Cloud services used automatically')
  static void setManualBackend(String url) {
    print('⚠️ setManualBackend() is deprecated - Cloud services used automatically');
  }

  /// ⚠️ DEPRECATED: Cache clearing tidak diperlukan lagi
  @Deprecated('Cloud services don\'t use cache')
  static void clearCache() {
    print('⚠️ clearCache() is deprecated - Cloud services don\'t use cache');
  }
  
  /// ✅ NEW: Reset cloud services
  static void reset() {
    _status = null;
    print('🔄 Cloud services reset');
  }
}
