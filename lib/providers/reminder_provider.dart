import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/reminder/reminder_service.dart';
import '../features/reminder/data/reminder_response_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/logging/data/logging_repository.dart';

/// Provides the ReminderService singleton with its required dependencies.
///
/// ReminderService needs:
/// - ProfileRepository: to check notificationPermissionGranted and userId
/// - LoggingRepository: to increment remindersSent in DailySummary
/// - ReminderResponseRepository: to create pending ReminderResponse at schedule time (F-06/F-08)
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final profileRepo = ref.read(profileRepositoryProvider);
  final loggingRepo = ref.read(loggingRepositoryProvider);
  final responseRepo = ref.read(reminderResponseRepositoryProvider);
  return ReminderService(profileRepo, loggingRepo, responseRepo);
});
