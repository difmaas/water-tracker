import '../../../core/constants/app_constants.dart';

/// Pure domain logic for the reminder interval system per WTASLL.md.
class ReminderLogic {
  /// Returns true if [now] falls within the active reminder window.
  static bool isWithinWindow(DateTime now, {int? startHour, int? endHour}) {
    final start = startHour ?? kReminderWindowStart;
    final end = endHour ?? kReminderWindowEnd;
    return now.hour >= start && now.hour < end;
  }

  /// Calculates the next reminder time based on the user's preference
  /// ('smart' or 'interval'), specific intervals, and daily progress.
  static DateTime nextReminderTime(
    DateTime now, {
    required String reminderType,
    required int reminderIntervalHours,
    required double progress,
    int? startHour,
    int? endHour,
  }) {
    final start = startHour ?? kReminderWindowStart;
    final end = endHour ?? kReminderWindowEnd;

    final windowEnd = DateTime(now.year, now.month, now.day, end);
    final firstReminderToday = DateTime(
      now.year,
      now.month,
      now.day,
      start,
      30,
    );

    // If progress is > 80% or target is reached, the next reminder is always tomorrow morning
    if (progress > 0.8) {
      return DateTime(now.year, now.month, now.day + 1, start, 30);
    }

    if (now.isBefore(firstReminderToday)) {
      return firstReminderToday;
    }

    if (reminderType == 'smart') {
      // Smart Reminder (Dynamic 3-Tier logic)
      // progress < 40% -> remind every 60 min
      // progress 40–80% -> remind every 90 min
      final int intervalMinutes = progress < 0.4 ? 60 : 90;
      final next = now.add(Duration(minutes: intervalMinutes));

      if (next.isAfter(windowEnd) || next.isAtSameMomentAs(windowEnd)) {
        return DateTime(now.year, now.month, now.day + 1, start, 30);
      }
      return next;
    } else {
      // Interval Reminder
      final next = now.add(Duration(hours: reminderIntervalHours));

      if (next.isAfter(windowEnd) || next.isAtSameMomentAs(windowEnd)) {
        return DateTime(now.year, now.month, now.day + 1, start, 30);
      }

      return next;
    }
  }
}
