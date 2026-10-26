import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'atomiclife_habits';
  static const String _channelName = 'Recordatorios de hábitos';
  static const String _channelDescription =
      'Recordatorios de los hábitos programados en AtomicLife';

  bool _initialized = false;

  // Inicializar el sistema de notificaciones.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: initializationSettings);

    _initialized = true;
  }

  // Solicitar al usuario permiso para mostrar notificaciones.
  Future<bool> requestPermission() async {
    await initialize();

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      return false;
    }

    return await android.requestNotificationsPermission() ?? false;
  }

  // Mostrar una notificación inmediata para pruebas.
  Future<void> showTestNotification() async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _notifications.show(
      id: 900000001,
      title: 'AtomicLife',
      body: '¡Las notificaciones están configuradas!',
      notificationDetails: details,
    );
  }

  // Crear un identificador estable por hábito y día.
  //
  // Para producción convendrá persistir identificadores
  // únicos si se requiere eliminar totalmente el riesgo
  // de colisión entre hábitos.
  int _notificationId(String habitId, int weekDay) {
    var hash = 2166136261;

    for (final character in habitId.codeUnits) {
      hash ^= character;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }

    final baseId = hash % 200000000;

    return baseId * 7 + weekDay;
  }

  // Calcular la próxima fecha válida de un día semanal.
  tz.TZDateTime _nextWeekdayTime({
    required int weekDay,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    var daysUntil = (weekDay - now.weekday + 7) % 7;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntil,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      daysUntil += 7;

      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntil,
        hour,
        minute,
      );
    }

    return scheduled;
  }

  // Programar los recordatorios semanales de un hábito.
  Future<void> scheduleHabitReminders({
    required String habitId,
    required String habitName,
    required String scheduledTime,
    required List<int> weekDays,
    required bool isActive,
    String microAction = '',
  }) async {
    await initialize();

    if (habitId.trim().isEmpty) {
      throw ArgumentError('El identificador del hábito es obligatorio.');
    }

    if (weekDays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Los días deben estar entre 1 y 7.');
    }

    final timeParts = scheduledTime.split(':');

    if (timeParts.length != 2) {
      throw FormatException('La hora debe tener el formato HH:mm.');
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw FormatException('Hora del hábito no válida.');
    }

    // Cancelar la programación anterior del hábito.
    await cancelHabitReminders(habitId);

    // No generar recordatorios si está pausado.
    if (!isActive) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final body = microAction.trim().isNotEmpty
        ? microAction.trim()
        : 'Dedica unos minutos a tu hábito de hoy.';

    for (final weekDay in weekDays.toSet()) {
      final nextDate = _nextWeekdayTime(
        weekDay: weekDay,
        hour: hour,
        minute: minute,
      );

      await _notifications.zonedSchedule(
        id: _notificationId(habitId, weekDay),
        title: '¡Es momento de $habitName!',
        body: body,
        scheduledDate: nextDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: habitId,
      );

      debugPrint(
        'Recordatorio programado: $habitName - '
        'día $weekDay - $nextDate',
      );
    }
  }

  // Cancelar los recordatorios asociados a un hábito.
  Future<void> cancelHabitReminders(String habitId) async {
    await initialize();

    for (var weekDay = 1; weekDay <= 7; weekDay++) {
      await _notifications.cancel(id: _notificationId(habitId, weekDay));
    }
  }

  // Consultar notificaciones pendientes.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();

    return _notifications.pendingNotificationRequests();
  }
}
