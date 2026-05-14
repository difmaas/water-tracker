import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderService {
  Future<void> rescheduleIfNeeded() async {
    // TODO: Implement notification rescheduling logic
    // Fires silently on app open
  }

  Future<void> initialize() async {
    // Called after profile confirmation
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());
