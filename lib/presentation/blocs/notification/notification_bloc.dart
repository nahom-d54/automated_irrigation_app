import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/domain/entities/notification.dart';
import 'package:irrigation_app/domain/entities/notification_settings.dart';
import 'package:irrigation_app/services/notification_service.dart';
part 'notification_state.dart';
part 'notification_event.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationSubscription;
  final List<AppNotification> _notifications = [];

  NotificationBloc() : super(NotificationInitial()) {
    on<NotificationInitialize>(_onInitialize);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationClearAll>(_onClearAll);
    on<NotificationUpdateSettings>(_onUpdateSettings);
    on<NotificationLoadSettings>(_onLoadSettings);
  }

  Future<void> _onInitialize(
    NotificationInitialize event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    
    try {
      await _notificationService.initialize();
      
      // Listen to notification stream
      _notificationSubscription = _notificationService.notificationStream.listen(
        (notification) {
          add(NotificationReceived(notification));
        },
      );

      final settings = _notificationService.settings;
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      
      emit(NotificationLoaded(
        notifications: List.from(_notifications),
        settings: settings,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    _notifications.insert(0, event.notification);
    
    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      emit(currentState.copyWith(
        notifications: List.from(_notifications),
        unreadCount: unreadCount,
      ));
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        emit(currentState.copyWith(
          notifications: List.from(_notifications),
          unreadCount: unreadCount,
        ));
      }
    }
  }

  Future<void> _onClearAll(
    NotificationClearAll event,
    Emitter<NotificationState> emit,
  ) async {
    _notifications.clear();
    
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      emit(currentState.copyWith(
        notifications: [],
        unreadCount: 0,
      ));
    }
  }

  Future<void> _onUpdateSettings(
    NotificationUpdateSettings event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.updateSettings(event.settings);
      
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        emit(currentState.copyWith(settings: event.settings));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadSettings(
    NotificationLoadSettings event,
    Emitter<NotificationState> emit,
  ) async {
    final settings = _notificationService.settings;
    
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      emit(currentState.copyWith(settings: settings));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
} 