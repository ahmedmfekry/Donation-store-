import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Initialize
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Notification clicked: ${response.payload}');
        }
      },
    );

    // Request permission (Android 13+)
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'تنبيهات انتهاء الصلاحية',
      channelDescription: 'إشعارات عند اقتراب انتهاء صلاحية الأصناف',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule daily check for expiring items
  Future<void> scheduleDailyExpiryCheck() async {
    // Cancel any existing scheduled notifications
    await _notifications.cancelAll();

    // Schedule daily notification at 9 AM
    await _notifications.zonedSchedule(
      0,
      'فحص الأصناف',
      'تم فحص المخزن للأصناف القريبة من انتهاء الصلاحية',
      _nextInstanceOf9AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_check_channel',
          'الفحص اليومي',
          channelDescription: 'فحص يومي للأصناف القريبة من انتهاء الصلاحية',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Show expiry warning notification
  Future<void> showExpiryWarning({
    required String itemName,
    required DateTime expiryDate,
    required int daysLeft,
  }) async {
    await showNotification(
      id: expiryDate.hashCode,
      title: '⚠️ تحذير: صنف قريب من انتهاء الصلاحية',
      body: '$itemName سينتهي خلال $daysLeft يوم (${_formatDate(expiryDate)})',
      payload: itemName,
    );
  }

  // Show expired item notification
  Future<void> showExpiredNotification({
    required String itemName,
    required DateTime expiryDate,
  }) async {
    await showNotification(
      id: expiryDate.hashCode + 1000,
      title: '🚫 تنبيه: صنف منتهي الصلاحية',
      body: '$itemName انتهت صلاحيته في ${_formatDate(expiryDate)}',
      payload: itemName,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
