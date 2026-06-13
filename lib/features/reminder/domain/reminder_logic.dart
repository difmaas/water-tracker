import '../../../core/constants/app_constants.dart';

/// Pure domain logic for the reminder interval system per WTASLL.md.
class ReminderLogic {
  static const int fixedIntervalHours = 2;

  /// Production supports only 1, 2, or 3 hour intervals.
  /// Invalid persisted values fall back to 2 hours to avoid stuck scheduling.
  static int normalizeIntervalHours(int value) {
    if (value == 1 || value == 2 || value == 3) return value;
    return fixedIntervalHours;
  }

  /// Returns true if [now] falls within the active reminder window.
  static bool isWithinWindow(DateTime now, {int? startHour, int? endHour}) {
    final (start, end) = normalizedWindow(startHour, endHour);
    return now.hour >= start && now.hour < end;
  }

  /// Returns all future fixed interval slots for the current local day only.
  static List<DateTime> remainingSlotsForToday(
    DateTime now, {
    required int reminderIntervalHours,
    int? startHour,
    int? endHour,
  }) {
    final (start, end) = normalizedWindow(startHour, endHour);
    final intervalHours = normalizeIntervalHours(reminderIntervalHours);

    final windowEndToday = DateTime(now.year, now.month, now.day, end);
    if (now.isAfter(windowEndToday)) return const [];

    final slots = <DateTime>[];
    var slot = DateTime(now.year, now.month, now.day, start);
    while (!slot.isAfter(windowEndToday)) {
      if (slot.isAfter(now)) {
        slots.add(slot);
      }
      slot = slot.add(Duration(hours: intervalHours));
    }

    return slots;
  }

  /// Calculates the next fixed interval reminder slot inside the active window.
  ///
  /// The persisted [reminderType], [reminderIntervalHours], and [progress]
  /// arguments are kept for API compatibility with the existing codebase.
  static DateTime nextReminderTime(
    DateTime now, {
    required String reminderType,
    required int reminderIntervalHours,
    required double progress,
    int? startHour,
    int? endHour,
  }) {
    final (start, end) = normalizedWindow(startHour, endHour);
    final intervalHours = normalizeIntervalHours(reminderIntervalHours);

    final firstSlotToday = DateTime(now.year, now.month, now.day, start);
    final windowEndToday = DateTime(now.year, now.month, now.day, end);
    final firstSlotTomorrow = DateTime(now.year, now.month, now.day + 1, start);

    if (now.isBefore(firstSlotToday)) {
      return firstSlotToday;
    }

    if (!now.isBefore(windowEndToday)) {
      return firstSlotTomorrow;
    }

    var nextSlot = firstSlotToday;
    while (!nextSlot.isAfter(now)) {
      nextSlot = nextSlot.add(Duration(hours: intervalHours));
    }

    if (!nextSlot.isBefore(windowEndToday)) {
      return firstSlotTomorrow;
    }

    return nextSlot;
  }

  static (int, int) normalizedWindow(int? startHour, int? endHour) {
    final start = startHour ?? kReminderWindowStart;
    final end = endHour ?? kReminderWindowEnd;
    final isValid =
        start >= 6 && start <= 22 && end >= 6 && end <= 22 && end - start >= 8;

    if (isValid) {
      return (start, end);
    }

    return (kReminderWindowStart, kReminderWindowEnd);
  }
}
