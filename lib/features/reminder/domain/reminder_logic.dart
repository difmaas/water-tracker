import '../../../core/constants/app_constants.dart';

/// Pure domain logic for the reminder interval system per WTASLL.md.
class ReminderLogic {
  /// Returns true if [now] falls within the active reminder window.
  static bool isWithinWindow(
    DateTime now, {
    int? startHour,
    int? endHour,
  }) {
    final start = startHour ?? kReminderWindowStart;
    final end = endHour ?? kReminderWindowEnd;
    return now.hour >= start && now.hour < end;
  }

  /// Calculates the next reminder time based on the user's preference
  /// ('smart' or 'interval') and the specific intervals.
  static DateTime nextReminderTime(
    DateTime now, {
    required String reminderType,
    required int reminderIntervalHours,
    int? startHour,
    int? endHour,
  }) {
    final start = startHour ?? kReminderWindowStart;
    final end = endHour ?? kReminderWindowEnd;

    final windowEnd = DateTime(now.year, now.month, now.day, end);

    if (reminderType == 'smart') {
      // Smart Reminder: 3 times a day
      // 1. 30 mins after wake up
      // 2. Mid day
      // 3. 30 mins before bed
      final t1 = DateTime(now.year, now.month, now.day, start, 30);
      final t2 = DateTime(now.year, now.month, now.day, (start + end) ~/ 2, 0);
      final t3 = DateTime(now.year, now.month, now.day, end - 1, 30); // 30 mins before endHour

      if (now.isBefore(t1)) return t1;
      if (now.isBefore(t2)) return t2;
      if (now.isBefore(t3)) return t3;

      // Tomorrow
      return DateTime(now.year, now.month, now.day + 1, start, 30);
    } else {
      // Interval Reminder
      final firstReminderToday = DateTime(now.year, now.month, now.day, start, 30);

      if (now.isBefore(firstReminderToday)) {
        return firstReminderToday;
      }

      // Next is now + interval
      final next = now.add(Duration(hours: reminderIntervalHours));

      if (next.isAfter(windowEnd) || next.isAtSameMomentAs(windowEnd)) {
        return DateTime(now.year, now.month, now.day + 1, start, 30);
      }

      return next;
    }
  }
}
