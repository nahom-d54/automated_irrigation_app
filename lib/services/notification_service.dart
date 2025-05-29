import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as nf;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:irrigation_app/domain/entities/notification.dart';
import 'package:irrigation_app/domain/entities/notification_settings.dart';
import 'package:irrigation_app/data/models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final nf.FirebaseMessaging _firebaseMessaging = nf.FirebaseMessaging.instance;
  
  final StreamController<AppNotification> _notificationStreamController = 
      StreamController<AppNotification>.broadcast();
  
  Stream<AppNotification> get notificationStream => _notificationStreamController.stream;
  
  bool _isInitialized = false;
  NotificationSettings? _settings;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      await _loadSettings();
      _isInitialized = true;
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for iOS
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Handle foreground messages
      nf.FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      nf.FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps when app is in background
      nf.FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _handleForegroundMessage(nf.RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    final notification = _createNotificationFromRemoteMessage(message);
    _notificationStreamController.add(notification);

    // Show local notification if enabled
    if (_settings?.inAppNotificationsEnabled ?? true) {
      await _showLocalNotification(notification);
    }
  }

  static Future<void> _handleBackgroundMessage(nf.RemoteMessage message) async {
    print('Received background message: ${message.messageId}');
  }

  Future<void> _handleNotificationTap(nf.RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    final notification = _createNotificationFromRemoteMessage(message);
    _notificationStreamController.add(notification);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        final notification = NotificationModel.fromJson(data);
        _notificationStreamController.add(notification);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  AppNotification _createNotificationFromRemoteMessage(nf.RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Irrigation Alert',
      message: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      category: _parseNotificationCategory(message.data['category']),
      timestamp: DateTime.now(),
      data: message.data,
      actionUrl: message.data['action_url'],
    );
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'critical':
        return NotificationType.critical;
      case 'warning':
        return NotificationType.warning;
      case 'success':
        return NotificationType.success;
      default:
        return NotificationType.info;
    }
  }

  NotificationCategory _parseNotificationCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'sensor_alert':
        return NotificationCategory.sensorAlert;
      case 'system_alert':
        return NotificationCategory.systemAlert;
      case 'irrigation_alert':
        return NotificationCategory.irrigationAlert;
      case 'connection_alert':
        return NotificationCategory.connectionAlert;
      case 'maintenance_alert':
        return NotificationCategory.maintenanceAlert;
      default:
        return NotificationCategory.systemAlert;
    }
  }

  Future<void> showNotification(AppNotification notification) async {
    if (!_isInitialized) await initialize();

    // Check if notifications are enabled and not in quiet hours
    if (!_shouldShowNotification(notification)) return;

    _notificationStreamController.add(notification);

    if (_settings?.pushNotificationsEnabled ?? true) {
      await _showLocalNotification(notification);
    }
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      'irrigation_alerts',
      'Irrigation Alerts',
      channelDescription: 'Notifications for irrigation system alerts',
      importance: _getImportance(notification.type),
      priority: _getPriority(notification.type),
      icon: '@mipmap/ic_launcher',
      color: Colors.blue,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: json.encode(NotificationModel(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        category: notification.category,
        timestamp: notification.timestamp,
        data: notification.data,
        actionUrl: notification.actionUrl,
      ).toJson()),
    );
  }

  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.critical:
        return Importance.max;
      case NotificationType.warning:
        return Importance.high;
      case NotificationType.info:
        return Importance.defaultImportance;
      case NotificationType.success:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.critical:
        return Priority.max;
      case NotificationType.warning:
        return Priority.high;
      case NotificationType.info:
        return Priority.defaultPriority;
      case NotificationType.success:
        return Priority.low;
    }
  }

  int? _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.critical:
        return 0xFFD32F2F; // Red
      case NotificationType.warning:
        return 0xFFFF9800; // Orange
      case NotificationType.success:
        return 0xFF4CAF50; // Green
      case NotificationType.info:
        return 0xFF2196F3; // Blue
    }
  }

  bool _shouldShowNotification(AppNotification notification) {
    if (_settings == null) return true;

    // Check if category is enabled
    if (!_settings!.enabledCategories.contains(notification.category)) {
      return false;
    }

    // Check quiet hours
    if (_settings!.quietHours.isInQuietHours(DateTime.now()) && 
        notification.type != NotificationType.critical) {
      return false;
    }

    return true;
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    _settings = settings;
    await _saveSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null) {
        // Parse and load settings (simplified for this example)
        _settings = NotificationSettings(
          sensorThresholds: SensorThresholds(),
          systemAlerts: SystemAlertSettings(),
          quietHours: TimeRange(),
        );
      } else {
        _settings = NotificationSettings(
          sensorThresholds: SensorThresholds(),
          systemAlerts: SystemAlertSettings(),
          quietHours: TimeRange(),
        );
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      _settings = NotificationSettings(
        sensorThresholds: SensorThresholds(),
        systemAlerts: SystemAlertSettings(),
        quietHours: TimeRange(),
      );
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save settings (simplified for this example)
      await prefs.setString('notification_settings', json.encode({
        'push_enabled': _settings?.pushNotificationsEnabled,
        'in_app_enabled': _settings?.inAppNotificationsEnabled,
        'email_enabled': _settings?.emailNotificationsEnabled,
      }));
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  NotificationSettings? get settings => _settings;

  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }
}
