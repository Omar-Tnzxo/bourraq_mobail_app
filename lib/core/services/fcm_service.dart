import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/core/router/app_router.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Background message: ${message.messageId}');
}

/// FCM Service for handling push notifications
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 [FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications
        await _initLocalNotifications();

        // Get FCM token
        await _getToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_onTokenRefresh);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification taps (when app is in background)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check for initial notification (when app was terminated)
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      }
    } catch (e) {
      debugPrint('🔔 [FCM] Initialization error: $e');
    }
  }

  /// Initialize local notifications for foreground
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_white_icon_logo',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'bourraq_notifications',
        'Bourraq Notifications',
        description: 'Notifications for orders, promotions, and updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get FCM token and save to database
  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('''
==================================================
🔔 [FCM] TEST DEVICE TOKEN:
$_fcmToken
==================================================
''');

      if (_fcmToken != null) {
        await _saveTokenToDatabase(_fcmToken!);
      }
    } catch (e) {
      debugPrint('🔔 [FCM] Get token error: $e');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    debugPrint('🔔 [FCM] Token refreshed: $token');
    _fcmToken = token;
    _saveTokenToDatabase(token);
  }

  /// Save FCM token to Supabase
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final client = Supabase.instance.client;
      final authUserId = client.auth.currentUser?.id;

      // Generate a unique device ID (you can use device_info_plus for a real ID)
      // Combining with userId logic ensures we don't hit RLS violations when different users sign in on same physical device.
      final rootDeviceId = '${Platform.operatingSystem}_${token.hashCode}';
      final deviceId = '${authUserId ?? "guest"}_$rootDeviceId';

      // App version from pubspec.yaml
      const appVersion = '1.0.0';

      await client.from('fcm_tokens').upsert({
        'device_id': deviceId,
        'user_id': authUserId, // use auth UUID to pass RLS policy
        'token': token,
        'app_type': 'customer',
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': appVersion,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');

      debugPrint('🔔 [FCM] Token saved to database');
    } catch (e) {
      debugPrint('🔔 [FCM] Save token error: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM] Foreground message: ${message.notification?.title}');

    // Track notification received
    AnalyticsService().trackNotificationReceived(
      notificationId: message.messageId ?? 'unknown',
      type: message.data['type'] ?? 'general',
    );

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Bourraq',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bourraq_notifications',
      'Bourraq Notifications',
      channelDescription: 'Notifications for orders, promotions, and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_white_icon_logo',
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap from background
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [FCM] Notification tapped: ${message.data}');

    // Track notification opened
    AnalyticsService().trackNotificationOpened(
      notificationId: message.messageId ?? 'unknown',
      type: message.data['type'] ?? 'general',
    );

    _navigateBasedOnData(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 [FCM] Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _navigateBasedOnData(data);
      } catch (e) {
        debugPrint('🔔 [FCM] Error parsing local notification payload: $e');
      }
    }
  }

  /// Navigate based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    debugPrint('🔔 [FCM] Navigating based on data: $data');
    final orderId = data['order_id'];
    final type = data['type'];
    final status = data['status'];

    if (orderId != null) {
      // If the notification type is rating or status is delivered, go to rating screen
      if (type == 'rate_order' ||
          type == 'order_delivered' ||
          (type == 'order_update' && status == 'delivered')) {
        AppRouter.router.push('/orders/$orderId/rating');
      } else {
        // Otherwise go to order details
        AppRouter.router.push('/orders/$orderId');
      }
    } else if (type == 'wallet' || type == 'transaction') {
      AppRouter.router.push('/wallet');
    } else if (type == 'promo') {
      AppRouter.router.push('/promo-codes');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('🔔 [FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('🔔 [FCM] Unsubscribed from topic: $topic');
  }
}
