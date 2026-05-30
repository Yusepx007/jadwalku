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

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = _nextInstanceOfWeekdayTime(day, hour, minute);

    // Hitung waktu pengingat dengan mengurangi menit yang ditentukan
    scheduledDate = scheduledDate.subtract(Duration(minutes: jadwal.pengingatMenit));

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    final String waktuDesc = jadwal.pengingatMenit == 0
        ? 'tepat waktu'
        : (jadwal.pengingatMenit == 60 ? '1 jam sebelumnya' : '${jadwal.pengingatMenit} menit sebelumnya');

    final String waktuText = jadwal.pengingatMenit == 0
        ? 'sekarang'
        : (jadwal.pengingatMenit == 60 ? '1 jam lagi' : '${jadwal.pengingatMenit} menit lagi');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jadwalku_channel',
      'Pengingat Jadwal Kuliah',
      channelDescription: 'Notifikasi pengingat jadwal kuliah $waktuDesc',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C63FF),
    );

    final NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      jadwal.id!,
      '🎓 ${jadwal.mataKuliah}',
      'Kuliah ${jadwal.mataKuliah} dimulai $waktuText di ${jadwal.ruangan}',
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
