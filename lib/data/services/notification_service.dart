import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<RemoteMessage>.broadcast();

  static const _tokenKey = 'fcm_device_token';

  // Tracks the logged-in email so token refreshes re-upload automatically.
  String? _email;

  static const _androidChannel = AndroidNotificationChannel(
    'earthly_jewels_orders',
    'Order Updates',
    description: 'Notifications for your Earthly Jewels order status',
    importance: Importance.high,
  );

  /// Emits whenever the user taps a notification (foreground / background / terminated).
  Stream<RemoteMessage> get onNotificationTap => _tapController.stream;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) {
        NotificationService.instance._tapController.add(RemoteMessage());
      },
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // Show notification when app is in foreground.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // App launched from terminated state via notification tap.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _tapController.add(initial);

    // App brought from background via notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen(_tapController.add);

    await _refreshToken();
    _fcm.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> _refreshToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _persistToken(token);
  }

  Future<void> _persistToken(String token) async {
    debugPrint('[FCM] Device token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _onTokenRefresh(String token) async {
    await _persistToken(token);
    if (_email != null) await _writeToFirestore(_email!, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Saves the FCM token to Firestore so Cloud Functions can look it up
  /// when a Shopify order event arrives.
  /// Call after login — re-runs automatically when the token refreshes.
  Future<void> uploadToken(String email) async {
    if (email.isEmpty) return;
    _email = email.trim().toLowerCase();
    final token = await getToken();
    if (token == null) return;
    await _writeToFirestore(_email!, token);
  }

  Future<void> _writeToFirestore(String email, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(email)
          .set({
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      debugPrint('[FCM] Token saved to Firestore for $email');
    } catch (e) {
      debugPrint('[FCM] Firestore write failed: $e');
    }
  }
}
