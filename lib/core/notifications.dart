import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();
bool _ready = false;

Future<void> initNotifications() async {
  if (_ready || kIsWeb) return;
  try {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _notifications.initialize(settings);
    _ready = true;
  } catch (_) {}
}

Future<void> pushNotification({
  required String title,
  required String body,
  int id = 0,
}) async {
  if (_ready || kIsWeb) return;
  try {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'incoex_tracking',
        'Tracking INCOEX',
        channelDescription: 'Notificaciones de estados del viaje',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
    await _notifications.show(
      id,
      title,
      body,
      details,
    );
  } catch (_) {
    // If local notifications fail (e.g. web), the in-app SnackBar still covers it
  }
}
