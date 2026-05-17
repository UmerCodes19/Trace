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
      String? token = await _fcm.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      
      if (token == null) {
        debugPrint('⚠️ [NotificationService] No FCM Token received.');
        return;
      }

      debugPrint('🎟️ [NotificationService] Syncing token for $userId');
      
      // CRITICAL FIX: To prevent "User 1 receiving User 2 notifications" on the same device,
      // we tell the backend to ensure this token ONLY belongs to THIS userId.
      await _apiService.dio.post('/api/users/sync-token', data: {
        'userId': userId,
        'token': token,
        'name': name,
        'email': email,
      });
      
      debugPrint('✅ [NotificationService] Token successfully synced.');
      
    } catch (e) {
      debugPrint('❌ [NotificationService] Error: $e');
    }
  }

  Future<void> unregisterDevice(String userId) async {
    debugPrint('📤 [NotificationService] Unregistering device for $userId...');
    try {
      // 1. Clear token from DB
      await _apiService.syncUser({
        'uid': userId,
        'fcm_token': null,
      });

      // 2. IMPORTANT: Delete token on device to force a fresh identity on next login
      await _fcm.deleteToken();
      
      debugPrint('✅ [NotificationService] Token cleared and deleted from device.');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error during unregister: $e');
    }
  }
}
