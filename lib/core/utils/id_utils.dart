import 'dart:math';

/// Generates a randomized, visually distinct participant ID.
///
/// Format: SEHATI-XXXX-XXXX
/// Where X is one of 32 non-ambiguous uppercase alphanumeric characters.
/// Excludes: 0, O, 1, I to prevent read errors by school researchers.
String generateParticipantId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();

  final code = List.generate(
    8,
    (_) => chars[random.nextInt(chars.length)],
  ).join();

  return 'SEHATI-${code.substring(0, 4)}-${code.substring(4, 8)}';
}
