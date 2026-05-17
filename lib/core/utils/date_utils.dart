/// Date utility helpers for the Personal Hydration Tracker.
class AppDateUtils {
  /// Derives age in years from a given birthdate.
  /// Age is recalculated at runtime — not stored as a field.
  static int ageFromBirthdate(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  /// Returns true if the derived age from the given birthdate is within
  /// the valid research participant range (10–80 years).
  static bool isValidAge(DateTime birthdate) {
    final age = ageFromBirthdate(birthdate);
    return age >= 10 && age <= 80;
  }

  /// Validates a user-configurable reminder window.
  ///
  /// Per AGENTS_V2 §17:
  /// - Minimum start: 06:00
  /// - Maximum end: 22:00
  /// - Minimum window: 8 hours (for adolescent sleep hygiene)
  ///
  /// Examples:
  ///   isValidReminderWindow(7, 21)  → true  (14h, default)
  ///   isValidReminderWindow(6, 14)  → true  (8h minimum)
  ///   isValidReminderWindow(6, 13)  → false (7h, below minimum)
  ///   isValidReminderWindow(5, 21)  → false (start before 06:00)
  ///   isValidReminderWindow(7, 23)  → false (end after 22:00)
  static bool isValidReminderWindow(int startHour, int endHour) {
    if (startHour < 6 || startHour > 22) return false;
    if (endHour < 6 || endHour > 22) return false;
    if (endHour - startHour < 8) return false;
    return true;
  }
}
