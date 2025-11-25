import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String name;
  final String deviceId;
  final String deviceName;
  final String homeId;
  final String? homeName;
  final String roomId;
  final String roomName;
  final String action;
  final Map<String, dynamic> actionData;
  final DateTime time;
  final List<String> repeatDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Schedule({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.deviceName,
    required this.homeId,
    this.homeName,
    required this.roomId,
    required this.roomName,
    required this.action,
    required this.actionData,
    required this.time,
    required this.repeatDays,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is Map<String, dynamic>) {
      // Handle Firestore timestamp as Map {seconds: ..., nanoseconds: ...}
      if (value.containsKey('_seconds') || value.containsKey('seconds')) {
        final seconds = value['_seconds'] ?? value['seconds'];
        final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000)
          );
        }
      }
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    } else if (value is DateTime) {
      return value;
    }
    
    return null;
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Schedule',
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? '',
      homeId: json['homeId'] ?? '',
      homeName: json['homeName'],
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      action: json['action'] ?? 'power',
      actionData: json['actionData'] ?? {},
      time: _parseDateTime(json['time']) ?? DateTime.now(),
      repeatDays: List<String>.from(json['repeatDays'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
        ? _parseDateTime(json['updatedAt'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'homeId': homeId,
      'homeName': homeName,
      'roomId': roomId,
      'roomName': roomName,
      'action': action,
      'actionData': actionData,
      'time': Timestamp.fromDate(time),
      'repeatDays': repeatDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Schedule copyWith({
    String? id,
    String? name,
    String? deviceId,
    String? deviceName,
    String? homeId,
    String? homeName,
    String? roomId,
    String? roomName,
    String? action,
    Map<String, dynamic>? actionData,
    DateTime? time,
    List<String>? repeatDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      homeId: homeId ?? this.homeId,
      homeName: homeName ?? this.homeName,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      action: action ?? this.action,
      actionData: actionData ?? this.actionData,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get next scheduled time based on repeat days
  DateTime getNextScheduledTime() {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If no repeat days, it's a one-time schedule
    if (repeatDays.isEmpty) {
      if (scheduledTime.isBefore(now)) {
        // Schedule has passed, return the original time
        return time;
      }
      return scheduledTime;
    }

    // Find next occurrence based on repeat days
    final weekdays = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };

    List<int> repeatWeekdays = repeatDays
        .map((day) => weekdays[day.toLowerCase()])
        .where((day) => day != null)
        .cast<int>()
        .toList()
      ..sort();

    if (repeatWeekdays.isEmpty) return scheduledTime;

    // Find next occurrence
    for (int i = 0; i < 7; i++) {
      final checkDate = scheduledTime.add(Duration(days: i));
      if (repeatWeekdays.contains(checkDate.weekday)) {
        if (checkDate.isAfter(now)) {
          return checkDate;
        }
      }
    }

    // If no future occurrence found in next 7 days, get the first one next week
    final nextWeek = scheduledTime.add(const Duration(days: 7));
    for (int weekday in repeatWeekdays) {
      final daysUntil = (weekday - nextWeek.weekday + 7) % 7;
      final nextOccurrence = nextWeek.add(Duration(days: daysUntil));
      return nextOccurrence;
    }

    return scheduledTime;
  }
}
