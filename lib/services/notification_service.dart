import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static void initialize() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'default_channel',
          channelName: 'Pengingat Pengiriman',
          channelDescription: 'Notifikasi pengingat harian pengiriman barang',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
        )
      ],
    );
  }

  static void requestPermissionIfNeeded() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> showDailyReminderNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'default_channel',
        title: 'Pengingat Pengiriman',
        body: 'Ayo lakukan pengiriman barang hari ini!',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
