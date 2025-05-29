part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class NotificationInitialize extends NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  final AppNotification notification;

  NotificationReceived(this.notification);

  @override
  List<Object> get props => [notification];
}

class NotificationMarkAsRead extends NotificationEvent {
  final String notificationId;

  NotificationMarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationClearAll extends NotificationEvent {}

class NotificationUpdateSettings extends NotificationEvent {
  final NotificationSettings settings;

  NotificationUpdateSettings(this.settings);

  @override
  List<Object> get props => [settings];
}

class NotificationLoadSettings extends NotificationEvent {} 