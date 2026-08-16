import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _currentToken;

  static Future<void> init() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleOpened(initial);

    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _persistToken(token);
    });

    AuthService().authStateChanges.listen((user) {
      if (user != null) _persistToken(_currentToken);
    });

    _currentToken = await _messaging.getToken();
    await _persistToken(_currentToken);
  }

  static Future<void> _persistToken(String? token) async {
    final uid = AuthService().currentUser?.uid;
    if (token == null || token.isEmpty || uid == null) return;
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users/$uid/fcm_token')
          .set(token);
    } catch (_) {}
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'MoonnLove';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'moonnlove_messages',
          'MoonnLove Chat',
          channelDescription: 'Notifikasi pesan & interaksi pasangan',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static void _handleOpened(RemoteMessage message) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil('/chat', (route) => route.isFirst);
  }
}
