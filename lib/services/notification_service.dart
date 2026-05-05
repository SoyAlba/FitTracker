// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _nativeChannel = MethodChannel('com.example.fittracker/permissions');
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'fittracker_main',
    'FitTracker Recordatorios',
    description: 'Alarmas y recordatorios de FitTracker',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'fittracker_main', 'FitTracker Recordatorios',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    ),
  );

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation('Europe/Madrid')); } catch (_) {}

    await _plugin.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    _initialized = true;
  }

  // ── Permisos ──────────────────────────────────────────────────────────────
  Future<bool> hasNotificationPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? true;

  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _nativeChannel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
    } catch (_) { return true; }
  }

  Future<void> openExactAlarmSettings() async {
    try { await _nativeChannel.invokeMethod('openExactAlarmSettings'); } catch (_) {}
  }

  Future<void> requestNotificationPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Notificación inmediata ────────────────────────────────────────────────
  Future<void> sendTestNotification() async {
    await _plugin.show(9999, '🔔 FitTracker', 'Las notificaciones funcionan ✅', _details);
  }

  // ── Programar ─────────────────────────────────────────────────────────────
  // alarmClock = mismo mecanismo que la app Reloj de Android.
  // No puede ser bloqueado por batería ni OxygenOS ni MIUI.
  // Requiere SCHEDULE_EXACT_ALARM — si no está concedido, abrimos ajustes.
  Future<int> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(id);
    final canExact = await canScheduleExactAlarms();
    final t = _nextTime(hour, minute);

    if (!canExact) {
      // Sin permiso exacto usamos inexacto — mejor que nada
      await _plugin.zonedSchedule(
        id, title, body, t, _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('⚠️ Sin SCHEDULE_EXACT_ALARM — usando inexacta $id → $hour:${minute.toString().padLeft(2,'0')}');
    } else {
      await _plugin.zonedSchedule(
        id, title, body, t, _details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('✅ alarmClock $id → $hour:${minute.toString().padLeft(2,'0')} próxima: $t');
    }
    return id;
  }

  Future<int> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(id);
    final canExact = await canScheduleExactAlarms();
    final t = _nextWeekday(weekday, hour, minute);

    await _plugin.zonedSchedule(
      id, title, body, t, _details,
      androidScheduleMode: canExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    debugPrint('✅ ${canExact ? "alarmClock" : "inexacta"} semanal $id → weekday=$weekday $hour:${minute.toString().padLeft(2,'0')}');
    return id;
  }

  // ── Recordatorio genérico ─────────────────────────────────────────────────
  Future<int> scheduleReminder({
    required String name,
    required String type,
    required int hour,
    required int minute,
    required String frequency,
    List<int>? customDays,
  }) async {
    final id = _idFor(name, hour, minute);
    final title = '${_emoji(type)} $name';
    final body = _body(type);

    switch (frequency) {
      case 'daily':
        await scheduleDaily(id: id, title: title, body: body, hour: hour, minute: minute);
      case 'weekdays':
        for (int i = 0; i < 5; i++) {
          await scheduleWeekly(id: id + i, title: title, body: body,
              weekday: i + 1, hour: hour, minute: minute);
        }
      case 'weekends':
        await scheduleWeekly(id: id,     title: title, body: body, weekday: 6, hour: hour, minute: minute);
        await scheduleWeekly(id: id + 1, title: title, body: body, weekday: 7, hour: hour, minute: minute);
      case 'weekly':
        final day = customDays?.first ?? DateTime.now().weekday;
        await scheduleWeekly(id: id, title: title, body: body,
            weekday: day, hour: hour, minute: minute);
      case 'custom':
        if (customDays != null)
          for (int i = 0; i < customDays.length; i++) {
            await scheduleWeekly(id: id + i, title: title, body: body,
                weekday: customDays[i], hour: hour, minute: minute);
          }
      default:
        await scheduleDaily(id: id, title: title, body: body, hour: hour, minute: minute);
    }
    return id;
  }

  Future<void> cancelNotification(int id) => _plugin.cancel(id);
  Future<void> cancelAllNotifications() => _plugin.cancelAll();

  // ── Helpers ───────────────────────────────────────────────────────────────
  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now.add(const Duration(seconds: 30)))) t = t.add(const Duration(days: 1));
    return t;
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var t = _nextTime(hour, minute);
    while (t.weekday != weekday) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  int _idFor(String name, int hour, int minute) =>
      (name.hashCode.abs() % 80000) + hour * 100 + minute + 5000;

  String _emoji(String type) => switch (type) {
    'injection' => '💉', 'supplement' => '💊', 'medication' => '🏥',
    'protein'   => '🥤', 'water'      => '💧', 'gym'        => '🏋️',
    'shopping'  => '🛒', 'weight'     => '⚖️', _            => '🔔',
  };

  String _body(String type) => switch (type) {
    'injection'  => 'Es la hora de tu inyección',
    'supplement' => 'No olvides tus suplementos',
    'medication' => 'Hora de tu medicación',
    'protein'    => 'Toma tu batido de proteína 🥤',
    'water'      => 'Bebe un vaso de agua 💧',
    'gym'        => '¡Es hora de entrenar! 💪',
    'shopping'   => 'Revisa tu lista de la compra',
    'weight'     => 'Pésate en ayunas',
    _            => 'Recordatorio de FitTracker',
  };

  Future<int> scheduleMedicalReminder({
    required String name, required String type,
    required int hour, required int minute, required bool daily,
  }) => scheduleReminder(
    name: name, type: type, hour: hour, minute: minute,
    frequency: daily ? 'daily' : 'weekly',
  );
}