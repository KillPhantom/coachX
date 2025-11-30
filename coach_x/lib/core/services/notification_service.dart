import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/firebase_options.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling a background message: ${message.messageId}');
}

/// Notification Service
///
/// Handles FCM token management, permission requests, and message display.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initialize Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('Initializing Notification Service...');

      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.info('User granted provisional permission');
      } else {
        AppLogger.warning('User declined or has not accepted permission');
        // We still continue to register handlers, but token might not be useful or UI won't show
      }

      // 2. Setup Local Notifications (for foreground)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.info('Notification tapped: ${response.payload}');
          // TODO: Implement navigation logic based on payload
        },
      );

      // Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('Got a message whilst in the foreground!');
        AppLogger.info('Message data: ${message.data}');

        if (message.notification != null) {
          AppLogger.info('Message also contained a notification: ${message.notification}');
          _showForegroundNotification(message, channel);
        }
      });

      // 5. Get Token and Save
      String? token = await _messaging.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      _isInitialized = true;
      AppLogger.info('Notification Service Initialized');
    } catch (e, s) {
      AppLogger.error('Failed to initialize NotificationService', e, s);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      AppLogger.warning('User not logged in, cannot save FCM token');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLogger.info('FCM Token saved to Firestore for user: $userId');
    } catch (e, s) {
      AppLogger.error('Error saving FCM token', e, s);
    }
  }

  Future<void> _showForegroundNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon, // Uses the same icon as initialized
            // importance: Importance.max, // Inherited from channel
            // priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}

