import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const bool kTestNotifications = false;

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'ets_reminders';
  static const _channelName = 'Recordatorios ETS';
  static const _kNotifKey = 'notifications_enabled';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

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
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kNotifKey) ?? false;
    if (!enabled) return;

    final anticipacion =
        prefs.getString('notification_anticipation') ?? '1_dia';

    int diasAntes;
    String mensajeAnticipacion;
    switch (anticipacion) {
      case '3_dias':
        diasAntes = 3;
        mensajeAnticipacion = 'En 3 días tienes';
      case '1_semana':
        diasAntes = 7;
        mensajeAnticipacion = 'En 1 semana tienes';
      default:
        diasAntes = 1;
        mensajeAnticipacion = 'Mañana tienes';
    }

    // Modo prueba: si el examen cae dentro del rango del recordatorio
    // configurado → disparar en 1 minuto para facilitar testing.
    final diasParaExamen =
        examDate.difference(DateTime.now()).inDays;
    final bool modoTest =
        kTestNotifications && diasParaExamen <= diasAntes && diasParaExamen >= 0;

    tz.TZDateTime scheduledDate;

    if (modoTest) {
      scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      debugPrint(
        '🔔 MODO TEST: Notificación de "$examName" en 1 minuto '
        '(examen en $diasParaExamen días, recordatorio: $diasAntes días antes)',
      );
    } else {
      final notifDate = examDate.subtract(Duration(days: diasAntes));
      scheduledDate = tz.TZDateTime(
        tz.local,
        notifDate.year,
        notifDate.month,
        notifDate.day,
        8,
        0,
      );
      debugPrint(
        '🔔 Notificación de "$examName" programada para $scheduledDate',
      );
    }

    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      debugPrint('⚠️ Notificación no programada: fecha ya pasó');
      return;
    }

    final titulo = modoTest
        ? '🧪 TEST — Recordatorio ETS'
        : 'Recordatorio ETS — MOVIDA';
    final cuerpo = modoTest
        ? 'PRUEBA: $mensajeAnticipacion tu ETS de $examName'
        : '$mensajeAnticipacion tu ETS de $examName';

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: scheduledDate,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: scheduledDate,
        notificationDetails: _details,
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
      notificationDetails: _details,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
