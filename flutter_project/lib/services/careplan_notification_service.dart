import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class CarePlanNotificationService {
  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> init() async {
    if (_isInitialized) return;

    // Initialize awesome notifications if not already done
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'careplan_updates',
          channelName: 'Care Plan Updates',
          channelDescription: 'Notifications when care plans are updated',
          importance: NotificationImportance.High,
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    // Request permissions if not granted
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    _isInitialized = true;
  }

  /// Show a care plan notification
  static Future<void> showCarePlanNotification({
    required String patientId,
    String? title,
    String? body,
  }) async {
    await init(); // Ensure initialized

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
        channelKey: 'careplan_updates',
        title: title ?? 'Care Plan Updated',
        body: body ?? 'Your care plan has been updated. Tap to view.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        payload: {
          'type': 'careplan_update',
          'patient_id': patientId,
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_CAREPLAN',
          label: 'View',
          actionType: ActionType.Default,
          enabled: true,
        ),
      ],
    );
  }

  /// Clear all care plan notifications
  static Future<void> clearNotifications() async {
    await AwesomeNotifications().cancelNotificationsByChannelKey('careplan_updates');
  }
}
