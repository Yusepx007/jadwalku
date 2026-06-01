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

    // Buat Notification Channel secara eksplisit dengan suara alarm kustom
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'jadwalku_alarm_channel_v2', // Menggunakan ID baru untuk mereset konfigurasi lama
        'Pengingat Jadwal Kuliah',
        description: 'Notifikasi pengingat jadwal kuliah dengan suara alarm kustom',
        importance: Importance.max, // Penting untuk memicu banner popup heads-up
        playSound: true,
        sound: RawResourceAndroidNotificationSound('custom_alarm'),
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  static Future<void> requestPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Minta izin POST_NOTIFICATIONS untuk Android 13+
      await androidPlugin.requestNotificationsPermission();
      // Minta izin SCHEDULE_EXACT_ALARM untuk Android 13/14+
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Gagal meminta izin exact alarm: $e');
      }
    }
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
      'jadwalku_alarm_channel_v2', // Harus cocok dengan ID channel yang dibuat eksplisit
      'Pengingat Jadwal Kuliah',
      channelDescription: 'Notifikasi pengingat jadwal kuliah $waktuDesc',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C63FF),
      sound: const RawResourceAndroidNotificationSound('custom_alarm'),
      playSound: true,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'custom_alarm.wav',
    );

    final NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
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
      debugPrint('Berhasil menjadwalkan notifikasi presisi untuk ${jadwal.mataKuliah} pada $scheduledDate');
    } catch (e) {
      debugPrint('Gagal menjadwalkan alarm presisi: $e. Mencoba fallback dengan inexactAllowWhileIdle.');
      // Fallback jika exact alarm diblokir/gagal
      try {
        await _notificationsPlugin.zonedSchedule(
          jadwal.id!,
          '🎓 ${jadwal.mataKuliah}',
          'Kuliah ${jadwal.mataKuliah} dimulai $waktuText di ${jadwal.ruangan}',
          scheduledDate,
          notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('Berhasil menjadwalkan notifikasi fallback (inexact) untuk ${jadwal.mataKuliah}');
      } catch (err) {
        debugPrint('Gagal total menjadwalkan notifikasi fallback: $err');
      }
    }
  }

  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jadwalku_alarm_channel_v2',
      'Pengingat Jadwal Kuliah',
      channelDescription: 'Channel untuk notifikasi alarm pengingat jadwal kuliah',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6C63FF),
      sound: RawResourceAndroidNotificationSound('custom_alarm'),
      playSound: true,
    );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: 'custom_alarm.wav',
      ),
    );

    await _notificationsPlugin.show(
      9999, // ID unik tes
      '🔔 Tes Notifikasi JadwalKu',
      'Ini adalah notifikasi uji coba dengan suara alarm kustom!',
      notifDetails,
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
