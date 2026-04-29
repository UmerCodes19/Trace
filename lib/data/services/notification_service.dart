import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 User granted notification permission');
    }

    // 2. Setup Local Notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground Message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 4. Handle Background/Terminated state clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🖱️ Notification Clicked: ${message.data}');
      // Handle navigation if needed
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'trace_notifications',
      'Trace Alerts',
      channelDescription: 'Mission-critical lost and found updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> registerDevice(String userId, {String? name, String? email}) async {
    debugPrint('🔍 [NotificationService] Starting registration for $userId...');
    try {
      // Add a timeout to prevent hanging on devices with bad connectivity/no Play Services
      debugPrint('🔍 [NotificationService] Requesting FCM token...');
      String? token = await _fcm.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏳ [NotificationService] FCM token request timed out after 10s');
          return null;
        },
      );
      
      if (token == null) {
        debugPrint('⚠️ [NotificationService] No FCM Token received (NULL). Push notifications disabled.');
        return;
      }

      debugPrint('🎟️ [NotificationService] FCM Token: ${token.substring(0, 10)}...');
      
      await _apiService.syncUser({
        'uid': userId,
        'fcm_token': token,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });
      debugPrint('✅ [NotificationService] Token successfully synced to database.');
      
    } catch (e) {
      debugPrint('❌ [NotificationService] Error: $e');
    }
  }
}
