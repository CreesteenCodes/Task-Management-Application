import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:tazk_application/models/note_item.dart';
import 'package:tazk_application/services/settings_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static int _scheduleOffsetDays(String schedule) {
    final normalized = schedule.trim().toLowerCase();
    if (normalized.contains('3')) {
      return 3;
    }
    if (normalized.contains('2')) {
      return 2;
    }
    if (normalized.contains('1')) {
      return 1;
    }
    return 0;
  }

  static DateTime? calculateReminderDateTime(
    DateTime? dueDate, {
      DateTime? now,
      String? overrideSchedule,
      TimeOfDay? overrideTime,
  }) {
    if (dueDate == null) {
      return null;
    }

    final settings = SettingsService();
    if (!settings.notificationsEnabled.value) {
      return null;
    }

    final currentTime = (now ?? DateTime.now()).toLocal();
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final reminderTime = overrideTime ?? settings.notificationTime.value;
    final scheduleOffsetDays = _scheduleOffsetDays(
      overrideSchedule ?? settings.notificationSchedule.value,
    );

    final reminderDate = dueDateOnly.subtract(
      Duration(days: scheduleOffsetDays),
    );
    final reminderDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    final nowDateTime = DateTime.fromMillisecondsSinceEpoch(
      currentTime.millisecondsSinceEpoch,
    );

    if (reminderDateTime.isBefore(nowDateTime)) {
      final sameDay = reminderDate.year == currentTime.year &&
          reminderDate.month == currentTime.month &&
          reminderDate.day == currentTime.day;
      if (!sameDay || reminderDateTime.isBefore(nowDateTime)) {
        developer.log(
          'NotificationService: reminder computed in the past dueDate=$dueDate reminderDateTime=$reminderDateTime now=$nowDateTime',
        );
        return null;
      }
    }

    return reminderDateTime;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _configureTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    developer.log('NotificationService: plugin initialized');
    await _requestPermissions();
    await _ensureAndroidChannel();
    developer.log('NotificationService: timezone=${tz.local.name}');
    _initialized = true;
  }

  Future<void> _configureTimezone() async {
    tz_data.initializeTimeZones();

    final systemZoneName = DateTime.now().timeZoneName;
    if (systemZoneName.isNotEmpty && systemZoneName != 'UTC' && systemZoneName != 'GMT') {
      try {
        if (systemZoneName.contains('/') || systemZoneName.contains('_')) {
          tz.setLocalLocation(tz.getLocation(systemZoneName));
          developer.log('NotificationService: timezone=$systemZoneName');
          return;
        }
      } catch (e, st) {
        developer.log('NotificationService: timezone lookup failed', error: e, stackTrace: st);
      }
    }

    try {
      tz.setLocalLocation(tz.UTC);
      developer.log('NotificationService: timezone=UTC');
    } catch (e, st) {
      tz.setLocalLocation(tz.local);
      developer.log('NotificationService: timezone=${tz.local.name}', error: e, stackTrace: st);
    }
  }

  Future<void> _ensureAndroidChannel() async {
    if (!Platform.isAndroid) {
      return;
    }

    final implementation = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await implementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'task_reminders',
        'Task reminders',
        description: 'Reminders for upcoming tasks',
        importance: Importance.max,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final notificationStatus = await Permission.notification.status;
        developer.log('NotificationService: Android notification permission status=$notificationStatus');
        if (notificationStatus.isDenied || notificationStatus.isRestricted || notificationStatus.isLimited) {
          final result = await Permission.notification.request();
          developer.log('NotificationService: Android notification permission request result=$result');
        }

        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        developer.log('NotificationService: Android exact alarm permission status=$exactAlarmStatus');
        if (exactAlarmStatus.isDenied || exactAlarmStatus.isRestricted || exactAlarmStatus.isLimited) {
          final result = await Permission.scheduleExactAlarm.request();
          developer.log('NotificationService: Android exact alarm permission request result=$result');
        }

        final batteryOptimizationStatus = await Permission.ignoreBatteryOptimizations.status;
        developer.log('NotificationService: Android battery optimization status=$batteryOptimizationStatus');
        if (batteryOptimizationStatus.isDenied || batteryOptimizationStatus.isRestricted || batteryOptimizationStatus.isLimited) {
          final result = await Permission.ignoreBatteryOptimizations.request();
          developer.log('NotificationService: Android battery optimization request result=$result');
        }
      } catch (e, st) {
        developer.log('NotificationService: permission check failed', error: e, stackTrace: st);
      }
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        final notificationsGranted = await androidPlugin?.requestNotificationsPermission();
        developer.log('NotificationService: Android notifications permission granted=$notificationsGranted');
      } catch (e, st) {
        developer.log('NotificationService: requestNotificationsPermission failed', error: e, stackTrace: st);
      }

      try {
        final exactAlarmGranted = await androidPlugin?.requestExactAlarmsPermission();
        developer.log('NotificationService: Android exact alarms permission granted=$exactAlarmGranted');
      } catch (e, st) {
        developer.log('NotificationService: requestExactAlarmsPermission failed', error: e, stackTrace: st);
      }
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<NoteItem> syncNotificationForNote(NoteItem note) async {
    await initialize();

    final notificationId = note.notificationId ?? _generateNotificationId(note);
    developer.log('syncNotificationForNote: id=$notificationId title=${note.title} due=${note.dueDate} status=${note.status}');
    await cancelNotification(notificationId);

    if (note.status == 'Completed') {
      return note.copyWith(notificationId: notificationId);
    }

    final settings = SettingsService();
    if (!settings.notificationsEnabled.value) {
      return note.copyWith(notificationId: notificationId);
    }

    final reminderDateTime = calculateReminderDateTime(
      NoteItem.parseDueDate(note.dueDate),
      now: DateTime.now(),
    );

    if (reminderDateTime != null) {
      final scheduledDateTime = tz.TZDateTime.from(reminderDateTime, tz.local);
      final nowTz = tz.TZDateTime.now(tz.local);
      developer.log('syncNotificationForNote: reminderDateTime=$reminderDateTime scheduledTZ=$scheduledDateTime nowTZ=$nowTz');
      if (scheduledDateTime.isAfter(nowTz) || scheduledDateTime.isAtSameMomentAs(nowTz)) {
        try {
          await _plugin.zonedSchedule(
            id: notificationId,
            title: 'Task Reminder',
            body: 'Your task ${note.title} is due soon.',
            scheduledDate: scheduledDateTime,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'task_reminders',
                'Task reminders',
                channelDescription: 'Reminders for upcoming tasks',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: note.title,
          );
          developer.log('syncNotificationForNote: scheduled id=$notificationId');
        } catch (e, st) {
          developer.log('syncNotificationForNote: scheduling failed', error: e, stackTrace: st);
        }
      } else {
        developer.log('syncNotificationForNote: scheduledDateTime is in the past, skipping');
      }
    } else {
      developer.log('syncNotificationForNote: no reminderDateTime (null)');
    }

    return note.copyWith(notificationId: notificationId);
  }

  Future<void> cancelNotification(int? notificationId) async {
    if (notificationId == null) {
      return;
    }

    try {
      await _plugin.cancel(id: notificationId);
      developer.log('cancelNotification: cancelled id=$notificationId');
    } catch (e, st) {
      developer.log('cancelNotification: failed to cancel id=$notificationId', error: e, stackTrace: st);
    }
  }

  /// Debug helper: show a notification immediately to validate device delivery.
  Future<void> showTestNotificationNow({String title = 'Test reminder'}) async {
    await initialize();
    try {
      await _plugin.show(
        id: 999999,
        title: title,
        body: 'This is a test notification generated by NotificationService.showTestNotificationNow()',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task reminders',
            channelDescription: 'Reminders for upcoming tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      developer.log('showTestNotificationNow: shown');
    } catch (e, st) {
      developer.log('showTestNotificationNow: failed', error: e, stackTrace: st);
    }
  }

  Future<List<NoteItem>> syncNotificationsForNotes(List<NoteItem> notes) async {
    await initialize();
    final syncedNotes = <NoteItem>[];
    for (final note in notes) {
      syncedNotes.add(await syncNotificationForNote(note));
    }
    return syncedNotes;
  }

  int _generateNotificationId(NoteItem note) {
    final seed = '${note.title}:${note.dueDate}:${note.category}:${note.status}:${note.description}'.hashCode;
    final positiveId = seed & 0x7fffffff;
    return positiveId == 0 ? 1 : positiveId;
  }
}
