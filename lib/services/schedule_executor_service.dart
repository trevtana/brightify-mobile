import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'mqtt_cloud_service.dart';

class ScheduleExecutorService {
  static final ScheduleExecutorService _instance = ScheduleExecutorService._internal();
  factory ScheduleExecutorService() => _instance;
  ScheduleExecutorService._internal();

  Timer? _executorTimer;
  final Set<String> _executedSchedules = {};
  final FirebaseService _firebaseService = FirebaseService();
  
  /// Start the schedule executor (runs every minute)
  void startExecutor() {
    if (_executorTimer?.isActive == true) {
      print('⚠️ Schedule executor already running');
      return;
    }
    
    print('🚀 Starting schedule executor...');
    
    // Run every minute
    _executorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _executeSchedules();
    });
    
    // Clear executed schedules cache every hour
    Timer.periodic(const Duration(hours: 1), (timer) {
      _executedSchedules.clear();
      print('🔄 Cleared executed schedules cache');
    });
    
    print('✅ Schedule executor started - checking every minute');
  }
  
  /// Stop the schedule executor
  void stopExecutor() {
    _executorTimer?.cancel();
    _executorTimer = null;
    print('🛑 Schedule executor stopped');
  }
  
  /// Main execution logic - runs every minute
  Future<void> _executeSchedules() async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final currentDay = _getCurrentDay(now.weekday);
      
      print('⏰ Checking schedules at $currentTime on $currentDay');
      
      int totalChecked = 0;
      int totalExecuted = 0;
      
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) {
        print('⚠️ No authenticated user, skipping schedule execution');
        return;
      }
      
      // Get all schedules from flat structure (mobile compatibility)
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('uid', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      for (final scheduleDoc in schedulesSnapshot.docs) {
        final schedule = scheduleDoc.data();
        final scheduleId = scheduleDoc.id;
        
        totalChecked++;
        
        // Check if schedule should execute now
        if (_shouldExecute(schedule, currentTime, currentDay, scheduleId)) {
          await _executeSchedule(schedule, scheduleId);
          totalExecuted++;
        }
      }
      
      if (totalExecuted > 0) {
        print('✅ Executed $totalExecuted schedules out of $totalChecked checked');
      } else if (totalChecked > 0) {
        print('📋 Checked $totalChecked schedules, none to execute at this time');
      }
      
    } catch (error) {
      print('❌ Schedule execution error: $error');
    }
  }
  
  /// Check if a schedule should execute now
  bool _shouldExecute(Map<String, dynamic> schedule, String currentTime, String currentDay, String scheduleId) {
    // Check if schedule is active
    if (schedule['isActive'] != true) {
      return false;
    }
    
    // Check if already executed this minute
    final executionKey = '${scheduleId}_$currentTime';
    if (_executedSchedules.contains(executionKey)) {
      return false;
    }
    
    // Check time match
    final scheduleTime = _formatScheduleTime(schedule['time']);
    if (scheduleTime != currentTime) {
      return false;
    }
    
    // Check day match
    final repeatDays = List<String>.from(schedule['repeatDays'] ?? []);
    if (repeatDays.isNotEmpty && !repeatDays.contains(_convertDayToMobile(currentDay))) {
      return false;
    }
    
    // Mark as executed
    _executedSchedules.add(executionKey);
    return true;
  }
  
  /// Execute a single schedule
  Future<void> _executeSchedule(Map<String, dynamic> schedule, String scheduleId) async {
    try {
      final deviceId = schedule['deviceId'] as String?;
      final action = schedule['action'] as String?;
      final actionData = schedule['actionData'] as Map<String, dynamic>?;
      
      if (deviceId == null || action == null || actionData == null) {
        print('⚠️ Invalid schedule data for $scheduleId');
        return;
      }
      
      print('🎯 Executing schedule: ${schedule['name']} for device $deviceId');
      
      // Send control command via API (same as web)
      await _sendDeviceControl(deviceId, actionData);
      
      print('✅ Schedule executed successfully: ${schedule['name']}');
      
    } catch (error) {
      print('❌ Failed to execute schedule $scheduleId: $error');
    }
  }
  
  /// Send device control command via MQTT
  Future<void> _sendDeviceControl(String deviceId, Map<String, dynamic> actionData) async {
    try {
      print('📡 Sending MQTT command to device $deviceId: $actionData');
      
      // Send via MQTT Cloud Service (same as manual control)
      final success = await MqttCloudService.controlDevice(deviceId, actionData);
      
      if (success) {
        print('✅ MQTT command sent successfully to $deviceId');
      } else {
        print('⚠️ MQTT command failed for device $deviceId');
      }
      
    } catch (error) {
      print('❌ Error sending MQTT command: $error');
    }
  }
  
  /// Format schedule time from various formats
  String _formatScheduleTime(dynamic timeData) {
    if (timeData is Timestamp) {
      final dateTime = timeData.toDate();
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (timeData is DateTime) {
      return '${timeData.hour.toString().padLeft(2, '0')}:${timeData.minute.toString().padLeft(2, '0')}';
    } else if (timeData is String) {
      return timeData;
    }
    return '00:00';
  }
  
  /// Get current day name
  String _getCurrentDay(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
  
  /// Convert web day format to mobile day format
  String _convertDayToMobile(String webDay) {
    const dayMapping = {
      'monday': 'Monday',
      'tuesday': 'Tuesday', 
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };
    return dayMapping[webDay] ?? webDay;
  }
}
