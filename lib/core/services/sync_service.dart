import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncService {
  Future<void> pushUnsyncedRecords() async {
    // TODO: Implement Supabase sync logic
    // Fire and forget - failures are silent
  }
}

final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
