import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../features/profile/data/user_profile_model.dart';
import '../features/dashboard/data/daily_summary_model.dart';

// Note: In a real app, you'd also include other models like HydrationLog, etc.
// But we'll start with these for F-00.

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main');
});
