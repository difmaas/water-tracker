AGENTS.md
AI Agent Rules — Personal Hydration Tracker
Read this file completely before writing any code, running any command, or making any structural decision.
Also read ARCHITECTURE.md and FEATURES.md before starting any session.
1. Project Identity
App Name: Personal Hydration Tracker
Platform: Android only (minSdkVersion 21, targetSdkVersion 34)
Language: Dart (null-safe, Dart 3.x)
Framework: Flutter (latest stable)
Purpose: Research instrument for OPSI — data integrity and research variable capture are first-class concerns
2. Mandatory Behavior Before Any Code
Before writing any code or running any command, the agent MUST:
Generate a plan artifact listing: affected files, new dependencies, folder changes, step-by-step execution order
Wait for explicit approval before proceeding
Never scaffold more than one feature at a time unless explicitly instructed
At the start of every session, answer these three questions first:
Which files were created or modified in the previous session?
Are there any known issues or TODOs left from the previous feature?
Does the app currently run without errors on Android?
3. Folder Structure — Canonical, Non-Negotiable
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_typography.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # kHydrationFacts, kHydrationArticles, kReminderWindow, kTargetClamp
│   ├── utils/
│   │   └── date_utils.dart
│   ├── services/
│   │   └── sync_service.dart        # Auto-sync on app open — not user-triggered
│   └── widgets/
│       ├── app_button.dart
│       └── app_card.dart
├── features/
│   ├── onboarding/
│   │   ├── presentation/
│   │   │   └── onboarding_screen.dart
│   │   └── onboarding_provider.dart
│   ├── profile/
│   │   ├── data/
│   │   │   ├── profile_repository.dart
│   │   │   └── user_profile_model.dart
│   │   ├── domain/
│   │   │   └── hydration_calculator.dart
│   │   └── presentation/
│   │       └── profile_screen.dart
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── progress_ring.dart
│   │   │       └── quick_add_buttons.dart
│   │   └── dashboard_provider.dart
│   ├── logging/
│   │   ├── data/
│   │   │   ├── hydration_log_model.dart
│   │   │   └── logging_repository.dart
│   │   └── presentation/
│   │       └── log_bottom_sheet.dart
│   ├── reminder/
│   │   ├── data/
│   │   │   └── reminder_response_model.dart
│   │   ├── domain/
│   │   │   └── reminder_logic.dart
│   │   └── reminder_service.dart
│   ├── education/
│   │   └── presentation/
│   │       ├── education_screen.dart
│   │       └── widgets/
│   │           └── article_card.dart
│   ├── gamification/
│   │   ├── data/
│   │   │   └── achievement_model.dart
│   │   ├── domain/
│   │   │   └── gamification_service.dart
│   │   └── presentation/
│   │       └── achievements_screen.dart
│   ├── progress/
│   │   └── presentation/
│   │       ├── progress_screen.dart
│   │       └── widgets/
│   │           ├── daily_chart.dart
│   │           └── weekly_chart.dart
│   └── export/
│       └── presentation/
│           └── export_screen.dart
└── providers/
    ├── profile_provider.dart
    ├── hydration_provider.dart
    ├── reminder_provider.dart
    └── gamification_provider.dart
Rules:
Never create files outside this structure without approval
core/widgets/ is for components used in 3+ features only
Single-use components go inside their feature's presentation/widgets/
Never create a screens/ or pages/ folder at root level
4. State Management — Riverpod
Use Riverpod exclusively. Never use setState, Provider (legacy), GetX, or Bloc
All screens extend ConsumerWidget or ConsumerStatefulWidget
Never use StatefulWidget directly unless managing purely local animation state
Provider naming: featureNameProvider in camelCase
dart
// CORRECT
final hydrationProvider = StateNotifierProvider<HydrationNotifier, HydrationState>((ref) {
  return HydrationNotifier(ref.read(loggingRepositoryProvider));
});

// INCORRECT
class _MyScreenState extends State<MyScreen> {
  int count = 0; // never put business logic in StatefulWidget
}
5. Local Database — Isar
Use Isar for all local persistence
Every collection needs @collection annotation
shared_preferences only for: isOnboarded (bool)
All Isar operations inside repository classes — never called from providers or UI directly
Every synced collection must include bool isSynced = false and DateTime createdAt
dart
// CORRECT — repository wraps Isar
class LoggingRepository {
  final Isar _isar;
  Future<void> saveLog(HydrationLog log) async {
    await _isar.writeTxn(() async {
      await _isar.hydrationLogs.put(log);
    });
  }
}
6. Backend — Supabase
Sync strategy: local-first, auto-sync on app open (silent, no user action required)
NO manual submit button. NO ConnectivityService. NO isSynced polling loop.
All writes go to Isar immediately
SyncService.pushUnsyncedRecords() called silently on every app open — fire and forget
Push order: user profile → hydration_logs → reminder_responses → daily_summaries
Mark isSynced: true only after confirmed Supabase write
Never expose Supabase client to UI layer
Authentication: Supabase anonymous auth — signInAnonymously() called once immediately after userId UUID is generated at profile setup, before saving UserProfile to Isar
user_id = locally generated UUID v4, stored in UserProfile.userId, used as FK in all Supabase tables
Researcher accesses all data directly via Supabase dashboard or admin query — no in-app export needed
7. Reminder System Rules
ReminderService.initialize() is called immediately after profile confirmation — NOT after first log
Check time against window (07:00–21:00) before scheduling
If setup outside window: schedule first reminder for tomorrow 07:00
Dynamic 3-tier logic (see ARCHITECTURE.md section 4)
Recalculate after every log and every app open
Use AndroidScheduleMode.exactAllowWhileIdle
Never schedule notifications if notificationPermissionGranted: false
On every app open: rebuild notification schedule unconditionally
Do NOT rely on previously scheduled notifications surviving device reboot
Assume all pending notifications are dead on app open — reschedule if needed
remindersSent counter in DailySummary is incremented inside ReminderService at the moment a notification is scheduled — not when it fires. This is intentional: fired status is unreliable on aggressive OEM devices.
These variables MUST be captured — they are research data, not optional:
notificationPermissionGranted — captured at onboarding
targetAccepted + manualTargetMl — captured at profile confirmation
loggedVia — on every hydration log ('app' or 'notification_action')
actionUsed — on every reminder response
sessionCount — incremented on every app open, persisted in DailySummary
firstLogTimestamp — first log of each day
dropoutFlag — detected via date comparison on app open, set if gap > 3 days
streakBreakHour — hour of last log on days streak is broken
If agent is about to implement any of these features without capturing these variables, STOP and add them first.
9. Dart Code Conventions
Naming
Files: snake_case.dart
Classes: PascalCase
Variables & functions: camelCase
Constants: kCamelCase (e.g., kDefaultWaterMl)
Private members: _leadingUnderscore
Null Safety
Never use ! without a null check guard above it
Prefer ?? and ?. operators
All model fields explicitly nullable or non-nullable
Performance
const constructors wherever possible
Never call heavy computation inside build()
All business logic in providers or services
Immutability
All model classes: final fields + copyWith() pattern
10. Navigation — go_router
go_router exclusively — never Navigator.push() directly
All routes in app_router.dart
Route name constants in app_constants.dart
11. Package Constraints
Approved Packages
Purpose	Package
State Management	flutter_riverpod
Local DB	isar + isar_flutter_libs
Backend	supabase_flutter
Notifications	flutter_local_notifications
Timezone	timezone
Charts	fl_chart
Progress UI	percent_indicator
Permissions	permission_handler
Onboarding	smooth_page_indicator
Navigation	go_router
Removed (no longer needed)
csv — no in-app CSV export
share_plus — no file sharing
path_provider — no local file writing
connectivity_plus — not needed, sync is fire-and-forget
Prohibited
get / GetX — never
provider (legacy) — never
hive — use Isar
Any unlisted package requires explicit approval
12. Error Handling
Never bare catch (e) without logging
All async repository operations use typed exceptions
UI handles loading, error, and empty states explicitly
Sync failures are silent — log to console, never show error to user (data safe in Isar)
13. What Agent Must Never Do
Never run flutter pub upgrade — only flutter pub get
Never delete or rename files without showing diff and getting approval
Never add Firebase — Supabase only
Never implement weather integration — out of scope
Never generate placeholder UI — all UI must be functional
Never mix business logic into build() methods
Never implement manual submit button — sync is automatic
Never skip research variable capture (section 8) when implementing relevant features
Never fetch education content from network — all content hardcoded in app_constants.dart
Never attempt to write or generate content for kHydrationArticles — content is provided by researcher, not generated
14. Scope Boundary
Phase 1 — Research Core (implement in order, stabilize before Phase 2)
Project Setup & Theme
Splash & Navigation Guard
Onboarding
Profile Setup + Hydration Calculator
Daily Dashboard
Hydration Logging
Reminder System
Direct Action Notification
Reminder Response Tracker
Education Screen (hardcoded content, no backend)
Auto-sync to Supabase (silent, on app open)
Phase 2 — Nice to Have (only if Phase 1 complete and stable)
Gamification + Streak (F-09)
Progress Screen charts (F-10)
Out of Scope Entirely
Manual "Kirim Data" submit button
CSV export from app
Admin panel or CMS
Dynamic/network-fetched education content
UI animations beyond functional feedback
Any feature not tied to research variable or user retention
15. Isar Model Definitions (Canonical)
All Isar collections must match these schemas exactly. Do not add or remove fields without approval.
dart
// UserProfile
@collection
class UserProfile {
  Id id = Isar.autoIncrement;
  late String userId;           // UUID v4, generated once at profile setup
  late String gender;           // 'male' | 'female'
  late int age;
  late double weightKg;
  late String activityLevel;    // 'sedentary'|'light'|'moderate'|'active'|'very_active'
  late int dailyTargetMl;
  late bool targetAccepted;
  int? manualTargetMl;
  late bool notificationPermissionGranted;
  late bool reminderSystemActive;
  late DateTime createdAt;
  DateTime? lastOpenedAt;       // updated on every app open
  bool dropoutFlag = false;
  bool isSynced = false;
}

// HydrationLog
@collection
class HydrationLog {
  Id id = Isar.autoIncrement;
  late String userId;
  late int volume;
  late DateTime timestamp;
  late String loggedVia;        // 'app' | 'notification_action'
  bool isSynced = false;
  late DateTime createdAt;
}

// ReminderResponse
@collection
class ReminderResponse {
  Id id = Isar.autoIncrement;
  late String userId;
  late bool completed;
  int? delayMinutes;
  String? actionUsed;           // 'button_250'|'button_500'|'opened_app'|'no_response'
  late DateTime timestamp;
  bool isSynced = false;
  late DateTime createdAt;
}

// DailySummary
@collection
class DailySummary {
  Id id = Isar.autoIncrement;
  late String userId;
  late DateTime date;
  late int targetMl;
  late int achievedMl;
  late double complianceRate;   // achievedMl / targetMl
  late int remindersSent;
  late int remindersResponded;
  late int sessionCount;        // incremented on every app open for this date
  late bool streakMaintained;   // complianceRate >= 0.8
  DateTime? firstLogTimestamp;
  int? streakBreakHour;         // hour of last log if streak broken
  bool dropoutFlag = false;
  bool isSynced = false;
  late DateTime createdAt;
}
dart
// DailySummary upsert logic (canonical — always follow this pattern)
Future<void> upsertDailySummary(String userId, DateTime date, ...) async {
  final existing = await _isar.dailySummarys
      .filter()
      .userIdEqualTo(userId)
      .dateEqualTo(date)
      .findFirst();

  if (existing != null) {
    // UPDATE: recalculate fields, preserve sessionCount and firstLogTimestamp
    final updated = existing.copyWith(
      achievedMl: newAchievedMl,
      complianceRate: newAchievedMl / existing.targetMl,
      remindersResponded: newRemindersResponded,
      isSynced: false, // mark dirty on every update
    );
    await _isar.writeTxn(() async => _isar.dailySummarys.put(updated));
  } else {
    // INSERT: create new record for today
    final summary = DailySummary()
      ..userId = userId
      ..date = date
      ..targetMl = targetMl
      ..achievedMl = newAchievedMl
      ..complianceRate = newAchievedMl / targetMl
      ..remindersSent = 0
      ..remindersResponded = 0
      ..sessionCount = 1
      ..streakMaintained = false
      ..isSynced = false
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.dailySummarys.put(summary));
  }
}
16. Midnight Reset Rule
Midnight reset is triggered by lazy date comparison on app open — never by a scheduled background job.
dart
// On every app open, before UI renders:
final lastDate = await profileRepository.getLastOpenedDate();
if (lastDate != null && lastDate.day != DateTime.now().day) {
  await performMidnightReset();
}
await profileRepository.updateLastOpenedAt(DateTime.now());
performMidnightReset() sequence:
Finalize DailySummary for yesterday (complianceRate, streakMaintained)
Update streak in UserProfile
Check and award achievements (if Phase 2 active)
Reset daily hydration state to 0
Cancel all pending notifications
Schedule first reminder for today at 07:00 (if within window)

17. User ID Strategy
Generated once as UUID v4 at profile setup
Stored in UserProfile.userId (Isar)
Used as foreign key in all Supabase tables
NOT Supabase anonymous auth UID
Rationale: app works fully offline; auth UID adds unnecessary complexity for a research instrument
Supabase anonymous auth still called for RLS compliance, but user_id FK uses local UUID
