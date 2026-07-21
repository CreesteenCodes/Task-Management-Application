import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kIsDark = 'settings_is_dark';
  static const _kEyeComfort = 'settings_eye_comfort';
  static const _kNotificationsEnabled = 'settings_notifications_enabled';
  static const _kNotificationHour = 'settings_notification_hour';
  static const _kNotificationMinute = 'settings_notification_minute';
  static const _kNotificationSchedule = 'settings_notification_schedule';
  static const _kDeletedNotes = 'deleted_notes';

  final ValueNotifier<bool> isDark = ValueNotifier(false);
  final ValueNotifier<bool> eyeComfort = ValueNotifier(false);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<TimeOfDay> notificationTime = ValueNotifier(
    const TimeOfDay(hour: 9, minute: 0),
  );
  final ValueNotifier<String> notificationSchedule = ValueNotifier('1 day before the due date');
  final ValueNotifier<int> deletedCount = ValueNotifier<int>(0);

  static final SettingsService _instance = SettingsService._internal();
  SettingsService._internal();
  factory SettingsService() => _instance;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getBool(_kIsDark) ?? false;
    eyeComfort.value = prefs.getBool(_kEyeComfort) ?? false;
    notificationsEnabled.value = prefs.getBool(_kNotificationsEnabled) ?? true;
    notificationTime.value = TimeOfDay(
      hour: prefs.getInt(_kNotificationHour) ?? 9,
      minute: prefs.getInt(_kNotificationMinute) ?? 0,
    );
    notificationSchedule.value = _normalizeNotificationSchedule(
      prefs.getString(_kNotificationSchedule) ?? '1 day before the due date',
    );
    deletedCount.value = (prefs.getStringList(_kDeletedNotes) ?? []).length;
  }

  Future<void> setDark(bool v) async {
    isDark.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, v);
  }

  Future<void> setEyeComfort(bool v) async {
    eyeComfort.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEyeComfort, v);
  }

  Future<void> setNotificationsEnabled(bool v) async {
    notificationsEnabled.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, v);
  }

  Future<void> setNotificationTime(TimeOfDay value) async {
    notificationTime.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotificationHour, value.hour);
    await prefs.setInt(_kNotificationMinute, value.minute);
  }

  Future<void> setNotificationSchedule(String value) async {
    final normalized = _normalizeNotificationSchedule(value);
    notificationSchedule.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotificationSchedule, normalized);
  }

  Future<void> refreshDeletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    deletedCount.value = (prefs.getStringList(_kDeletedNotes) ?? []).length;
  }

  Future<void> addDeletedNote(String json) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kDeletedNotes) ?? [];
    list.add(json);
    await prefs.setStringList(_kDeletedNotes, list);
    deletedCount.value = list.length;
  }

  String _normalizeNotificationSchedule(String schedule) {
    final normalized = schedule.trim().toLowerCase();
    if (normalized.contains('3')) {
      return '3 days before the due date';
    }
    if (normalized.contains('2')) {
      return '2 days before the due date';
    }
    if (normalized.contains('1')) {
      return '1 day before the due date';
    }
    if (normalized.contains('on due') || normalized.contains('on the due')) {
      return 'On the due date';
    }
    return '1 day before the due date';
  }
}
