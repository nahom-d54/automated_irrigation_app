part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final NotificationSettings? settings;
  final int unreadCount;

  NotificationLoaded({
    required this.notifications,
    this.settings,
    required this.unreadCount,
  });

  NotificationLoaded copyWith({
    List<AppNotification>? notifications,
    NotificationSettings? settings,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      settings: settings ?? this.settings,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object> get props => [notifications, settings ?? '', unreadCount];
}

class NotificationError extends NotificationState {
  final String message;

  NotificationError(this.message);

  @override
  List<Object> get props => [message];
} 