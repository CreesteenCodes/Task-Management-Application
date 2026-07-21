import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazk_application/services/notification_service.dart';
import 'package:tazk_application/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('NotificationService.calculateReminderDateTime', () {
    test(
      'schedules the day-before reminder for a due date two or more days away',
      () {
        final dueDate = DateTime(2026, 7, 20);
        final now = DateTime(2026, 7, 14, 10, 0);

        final reminder = NotificationService.calculateReminderDateTime(
          dueDate,
          now: now,
        );

        expect(reminder, DateTime(2026, 7, 19, 9, 0));
      },
    );

    test('skips the reminder when the reminder time has already passed', () {
      final dueDate = DateTime(2026, 7, 15);
      final now = DateTime(2026, 7, 14, 10, 0);

      final reminder = NotificationService.calculateReminderDateTime(
        dueDate,
        now: now,
      );

      expect(reminder, isNull);
    });

    test(
      'schedules for 9 AM today when the due date is tomorrow and it is still before 9 AM',
      () {
        final dueDate = DateTime(2026, 7, 15);
        final now = DateTime(2026, 7, 14, 8, 0);

        final reminder = NotificationService.calculateReminderDateTime(
          dueDate,
          now: now,
        );

        expect(reminder, DateTime(2026, 7, 14, 9, 0));
      },
    );

    test('handles leap-year month transitions correctly', () {
      final dueDate = DateTime(2024, 3, 1);
      final now = DateTime(2024, 2, 28, 8, 0);

      final reminder = NotificationService.calculateReminderDateTime(
        dueDate,
        now: now,
      );

      expect(reminder, DateTime(2024, 2, 29, 9, 0));
    });

    test('skips scheduling when notifications are disabled', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService().load();
      await SettingsService().setNotificationsEnabled(false);

      final reminder = NotificationService.calculateReminderDateTime(
        DateTime(2026, 7, 20),
        now: DateTime(2026, 7, 14, 10, 0),
      );

      expect(reminder, isNull);
    });
  });
}
