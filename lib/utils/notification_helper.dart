import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/jadwal_model.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
  }

  static Future<void> requestPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleWeeklyNotification(Jadwal jadwal) async {
    if (!jadwal.aktifNotif || jadwal.id == null) return;

    final day = _getDayOfWeek(jadwal.hari);
    if (day == null) return;

    final timeParts = jadwal.jamMulai.split(':');
    if (timeParts.length < 2) return;

    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    // 15 menit sebelum kuliah
    int reminderMinute = minute - 15;
    int reminderHour = hour;
    if (reminderMinute < 0) {
      reminderMinute += 60;
      reminderHour -= 1;
    }
    if (reminderHour < 0) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = _nextInstanceOfWeekdayTime(day, reminderHour, reminderMinute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jadwalku_channel',
      'Pengingat Jadwal Kuliah',
      channelDescription: 'Notifikasi pengingat jadwal kuliah 15 menit sebelumnya',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6C63FF),
    );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      jadwal.id!,
      '🎓 ${jadwal.mataKuliah}',
      'Kuliah ${jadwal.mataKuliah} dimulai 15 menit lagi di ${jadwal.ruangan}',
      scheduledDate,
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static int? _getDayOfWeek(String hari) {
    const map = {
      'Senin': DateTime.monday,
      'Selasa': DateTime.tuesday,
      'Rabu': DateTime.wednesday,
      'Kamis': DateTime.thursday,
      'Jumat': DateTime.friday,
      'Sabtu': DateTime.saturday,
    };
    return map[hari];
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
