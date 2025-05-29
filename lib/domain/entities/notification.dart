enum NotificationType {
  critical,
  warning,
  info,
  success,
}

enum NotificationCategory {
  sensorAlert,
  systemAlert,
  irrigationAlert,
  connectionAlert,
  maintenanceAlert,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final bool isPersistent;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.actionUrl,
    this.isPersistent = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool? isPersistent,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      isPersistent: isPersistent ?? this.isPersistent,
    );
  }
}
