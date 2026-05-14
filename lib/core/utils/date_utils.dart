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
}
