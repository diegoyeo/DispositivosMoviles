import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'ets_reminders';
  static const _channelName = 'Recordatorios ETS';
  static const _kNotifKey = 'notifications_enabled';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Solicitar permiso de alarmas exactas en Android 12+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleExamNotification({
    required int id,
    required String examName,
    required DateTime examDate,
  }) async {
    // Verificar que las notificaciones estén habilitadas por el usuario
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kNotifKey) ?? false;
    if (!enabled) return;

    // ── MODO PRUEBA: dispara 30 seg después de guardar ────────────────
    // TODO: revertir a modo producción antes de entregar
    final tzDate = tz.TZDateTime.now(tz.UTC).add(const Duration(seconds: 30));
    // ── MODO PRODUCCIÓN (descomentar y borrar las 2 líneas de arriba): ─
    // final localNotif = DateTime(
    //   examDate.year, examDate.month, examDate.day - 1, 8, 0,
    // );
    // if (!localNotif.isAfter(DateTime.now())) return;
    // final tzDate = tz.TZDateTime.from(localNotif.toUtc(), tz.UTC);
    // ─────────────────────────────────────────────────────────────────

    debugPrint('Notificación programada para: $tzDate');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Recordatorio ETS',
        body: 'Mañana tienes tu ETS de $examName',
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback a alarma inexacta si no hay permiso de alarma exacta
      await _plugin.zonedSchedule(
        id: id,
        title: 'Recordatorio ETS',
        body: 'Mañana tienes tu ETS de $examName',
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
