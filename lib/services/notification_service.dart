import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _notificationsEnabled = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    
    _isInitialized = true;
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    
    // Request exact alarm permission (Android 12+)
    final alarmStatus = await Permission.scheduleExactAlarm.request();
    
    print('📱 Notification permission: ${notificationStatus.isGranted}');
    print('⏰ Exact alarm permission: ${alarmStatus.isGranted}');
    
    return notificationStatus.isGranted && alarmStatus.isGranted;
  }

  // Check if exact alarm permission is granted
  Future<bool> canScheduleExactAlarms() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  // Enable/disable notifications
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await requestPermissions();
      await showNotification(
        title: 'Brightify',
        body: 'Notifikasi telah diaktifkan',
        id: 99999,
      );
    }
  }

  // Get notification status
  bool get isEnabled => _notificationsEnabled;

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    required int id,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'brightify_channel',
      'Brightify Notifications',
      channelDescription: 'Smart home control notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Schedule notification for specific time
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required int id,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;
    
    // Check if exact alarm permission is granted
    final canSchedule = await canScheduleExactAlarms();
    if (!canSchedule) {
      print('⚠️ Exact alarm permission not granted - requesting permission');
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('Alarm permission required to schedule notifications');
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'brightify_schedule',
      'Schedule Notifications',
      channelDescription: 'Notifications for scheduled device controls',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Schedule multiple notifications for a schedule
  Future<void> scheduleReminders({
    required String scheduleName,
    required DateTime scheduleTime,
    required int baseId,
  }) async {
    if (!_notificationsEnabled) return;

    // Cancel existing reminders for this schedule
    await cancelScheduleNotifications(baseId);

    // Schedule reminders at different intervals
    final intervals = [30, 20, 10, 5, 2]; // minutes before
    
    for (int i = 0; i < intervals.length; i++) {
      final reminderTime = scheduleTime.subtract(Duration(minutes: intervals[i]));
      
      // Only schedule if time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          title: 'Schedule Reminder',
          body: '$scheduleName akan aktif dalam ${intervals[i]} menit',
          id: baseId + i,
          scheduledTime: reminderTime,
          payload: 'schedule_${baseId}',
        );
      }
    }

    // Schedule notification for when schedule activates
    if (scheduleTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        title: 'Schedule Aktif',
        body: '$scheduleName telah diaktifkan',
        id: baseId + 10,
        scheduledTime: scheduleTime,
        payload: 'schedule_active_${baseId}',
      );
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all schedule notifications for a specific schedule
  Future<void> cancelScheduleNotifications(int baseId) async {
    // Cancel all reminders and activation notification
    for (int i = 0; i <= 10; i++) {
      await cancelNotification(baseId + i);
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Show device usage notification
  Future<void> showUsageNotification({
    required String deviceName,
    required int minutes,
  }) async {
    if (!_notificationsEnabled) return;

    await showNotification(
      title: 'Brightify Led',
      body: '$deviceName telah menyala selama $minutes menit',
      id: deviceName.hashCode,
      payload: 'usage_$deviceName',
    );
  }

  // Show power alert notification
  Future<void> showPowerAlert({
    required double powerUsage,
    required double cost,
  }) async {
    if (!_notificationsEnabled) return;

    await showNotification(
      title: 'Alert Penggunaan Daya',
      body: 'Penggunaan daya: ${powerUsage.toStringAsFixed(2)} kWh\nBiaya: Rp ${cost.toStringAsFixed(0)}',
      id: 88888,
      payload: 'power_alert',
    );
  }
}
