import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/config/firebase_config.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/storage_service.dart';
import '../../data/models/notification.dart';

/// Service for managing push notifications and local notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();

  StreamController<RemoteMessage>? _messageStreamController;
  StreamController<String>? _tokenStreamController;

  /// Initialize push notification service
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Configure Firebase Messaging
      await _configureFirebaseMessaging();

      // Get and store FCM token
      await _getFCMToken();

      // Set up token refresh listener
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      debugPrint('Push notification service initialized successfully');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Push Notification Init');
    }
  }

  /// Initialize local notifications
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
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const expenseChannel = AndroidNotificationChannel(
      'expense_updates',
      'Expense Updates',
      description: 'Notifications for expense updates and approvals',
      importance: Importance.high,
    );

    const tripChannel = AndroidNotificationChannel(
      'trip_updates',
      'Trip Updates',
      description: 'Notifications for trip updates and member activities',
      importance: Importance.defaultImportance,
    );

    const generalChannel = AndroidNotificationChannel(
      'general',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(expenseChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(tripChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }

    // Store permission status
    await _storage.setBool('notification_permissions_granted', 
        settings.authorizationStatus == AuthorizationStatus.authorized);
  }

  /// Configure Firebase Messaging
  Future<void> _configureFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _storage.setString('fcm_token', token);
        _tokenStreamController?.add(token);
        debugPrint('FCM Token: $token');
        
        // Log analytics event
        await FirebaseConfig.logEvent('fcm_token_received', {
          'token_length': token.length,
        });
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Get FCM Token');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) async {
    await _storage.setString('fcm_token', token);
    _tokenStreamController?.add(token);
    debugPrint('FCM Token refreshed: $token');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(message);
    
    // Add to message stream
    _messageStreamController?.add(message);
    
    // Log analytics event
    await FirebaseConfig.logEvent('notification_received_foreground', {
      'message_id': message.messageId,
      'data': message.data,
    });
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.messageId}');
    
    // Log analytics event
    await FirebaseConfig.logEvent('notification_received_background', {
      'message_id': message.messageId,
      'data': message.data,
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.messageId}');
    
    // Add to message stream
    _messageStreamController?.add(message);
    
    // Log analytics event
    await FirebaseConfig.logEvent('notification_tapped', {
      'message_id': message.messageId,
      'data': message.data,
    });
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) async {
    debugPrint('Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      // Handle navigation based on notification data
      _handleNotificationNavigation(data);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final channelId = _getChannelId(message.data);
    
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Get notification channel ID based on data
  String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'expense_update':
      case 'expense_approved':
      case 'expense_rejected':
        return 'expense_updates';
      case 'trip_update':
      case 'member_joined':
      case 'member_left':
        return 'trip_updates';
      default:
        return 'general';
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // TODO: Implement navigation logic based on notification data
    final type = data['type'] as String?;
    final tripId = data['tripId'] as String?;
    final expenseId = data['expenseId'] as String?;
    
    debugPrint('Navigate to: type=$type, tripId=$tripId, expenseId=$expenseId');
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
      
      // Log analytics event
      await FirebaseConfig.logEvent('topic_subscribed', {
        'topic': topic,
      });
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Subscribe to topic: $topic');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
      
      // Log analytics event
      await FirebaseConfig.logEvent('topic_unsubscribed', {
        'topic': topic,
      });
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Unsubscribe from topic: $topic');
    }
  }

  /// Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
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

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Send local notification');
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'expense_updates':
        return 'Expense Updates';
      case 'trip_updates':
        return 'Trip Updates';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'expense_updates':
        return 'Notifications for expense updates and approvals';
      case 'trip_updates':
        return 'Notifications for trip updates and member activities';
      default:
        return 'General app notifications';
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Get current token');
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get message stream
  Stream<RemoteMessage> get messageStream {
    _messageStreamController ??= StreamController<RemoteMessage>.broadcast();
    return _messageStreamController!.stream;
  }

  /// Get token stream
  Stream<String> get tokenStream {
    _tokenStreamController ??= StreamController<String>.broadcast();
    return _tokenStreamController!.stream;
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Dispose of resources
  void dispose() {
    _messageStreamController?.close();
    _tokenStreamController?.close();
  }
}
