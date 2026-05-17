import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles auto-sync of local records to Supabase.
/// Called as fire-and-forget on every app open.
///
/// ⚠️ V3 DECISION (AGENTS_V2 §6): Supabase integration is DEFERRED.
/// This is a NO-OP STUB during the feature development phase.
/// All data stays in Isar/SharedPreferences only.
///
/// When Supabase integration phase begins:
/// 1. Add auth session fallback (signInAnonymously if no session)
/// 2. Push order: users → hydration_logs → reminder_responses → daily_summaries
/// 3. Upsert strategy:
///    - users: .upsert() on local_user_id
///    - daily_summaries: .upsert(onConflict: 'user_id,date')
///    - hydration_logs: .insert() — each row unique
///    - reminder_responses: .insert() — each row unique
/// 4. Mark isSynced: true only after confirmed Supabase write
/// 5. Ensure nama NEVER appears in any Supabase payload
class SyncService {
  SyncService();

  /// No-op stub — logs a message and returns immediately.
  /// Will be replaced with actual sync logic during Supabase integration phase.
  Future<void> pushUnsyncedRecords() async {
    debugPrint('[SyncService] No-op stub — Supabase integration deferred');
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});
