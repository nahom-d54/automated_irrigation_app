import 'package:irrigation_app/domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.category,
    required super.timestamp,
    super.isRead,
    super.data,
    super.actionUrl,
    super.isPersistent,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      category: _parseNotificationCategory(json['category']),
      timestamp: _parseDateTime(json['timestamp']),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['action_url'] ?? json['actionUrl'],
      isPersistent: json['is_persistent'] ?? json['isPersistent'] ?? false,
    );
  }

  static NotificationType _parseNotificationType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'critical':
        return NotificationType.critical;
      case 'warning':
        return NotificationType.warning;
      case 'success':
        return NotificationType.success;
      case 'info':
      default:
        return NotificationType.info;
    }
  }

  static NotificationCategory _parseNotificationCategory(dynamic category) {
    switch (category?.toString().toLowerCase()) {
      case 'sensor_alert':
      case 'sensoralert':
        return NotificationCategory.sensorAlert;
      case 'system_alert':
      case 'systemalert':
        return NotificationCategory.systemAlert;
      case 'irrigation_alert':
      case 'irrigationalert':
        return NotificationCategory.irrigationAlert;
      case 'connection_alert':
      case 'connectionalert':
        return NotificationCategory.connectionAlert;
      case 'maintenance_alert':
      case 'maintenancealert':
        return NotificationCategory.maintenanceAlert;
      default:
        return NotificationCategory.systemAlert;
    }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else if (dateTime is num) {
      return DateTime.fromMillisecondsSinceEpoch((dateTime * 1000).toInt());
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
      'action_url': actionUrl,
      'is_persistent': isPersistent,
    };
  }
}
