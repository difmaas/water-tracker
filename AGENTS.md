# AI Agent Rules — Personal Hydration Tracker

> Read this file completely before writing any code, running any command, or making any structural decision.
> Also read ARCHITECTURE_V3.md and FEATURES_V3.md before starting any session.

> **V3 Changelog (2026-05-15):**
> - §6: Supabase integration deferred — all features must be complete and stable first
> - §7: Reminder window now user-configurable (06:00–22:00, min 8 hours, stored in UserProfile)
> - §8: Research variable — `dropoutNotificationSent` added to UserProfile schema
> - §15: Isar model updated — added `reminderWindowStart`, `reminderWindowEnd`, `currentStreak`, `dropoutNotificationSent`, new profile fields from F-03 refactor
> - §16: Splash startup sequence updated — no_response lazy detection added
> - §18: Supabase integration phase defined

---

## 1. Project Identity

- **App Name:** Personal Hydration Tracker
- **Platform:** Android only (minSdkVersion 21, targetSdkVersion 34)
- **Language:** Dart (null-safe, Dart 3.x)
- **Framework:** Flutter (latest stable)
- **Purpose:** Research instrument for OPSI — studying the effect of app-based hydration reminders on adolescent hydration behavior
- **Target Research Audience:** Remaja usia 13–18 tahun (app accepts any age — research scope is 13–18)

---

## 2. Mandatory Behavior Before Any Code

Before writing any code or running any command, the agent MUST:

1. Generate a **plan artifact** listing: affected files, new dependencies, folder changes, step-by-step execution order
2. Wait for explicit approval before proceeding
3. Never scaffold more than one feature at a time unless explicitly instructed
4. At the start of every session, answer these three questions first:
   - Which files were created or modified in the previous session?
   - Are there any known issues or TODOs left from the previous feature?
   - Does the app currently run without errors on Android?

---

## 3. Folder Structure — Canonical, Non-Negotiable

```
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
│   │   └── app_constants.dart
│   ├── utils/
│   │   └── date_utils.dart
│   ├── services/
│   │   └── sync_service.dart        # Deferred — not active until Supabase integration phase
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
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart
└── providers/
    ├── profile_provider.dart
    ├── hydration_provider.dart
    ├── reminder_provider.dart
    └── gamification_provider.dart
```

**Rules:**
- Never create files outside this structure without approval
- `core/widgets/` is for components used in 3+ features only
- Single-use components go inside their feature's `presentation/widgets/`
- Never create a `screens/` or `pages/` folder at root level
- `export/` folder removed — no CSV export in scope

---

## 4. State Management — Riverpod

- Use **Riverpod** exclusively. Never use `setState`, `Provider` (legacy), `GetX`, or `Bloc`
- All screens extend `ConsumerWidget` or `ConsumerStatefulWidget`
- Never use `StatefulWidget` directly unless managing purely local animation state
- Provider naming: `featureNameProvider` in camelCase

---

## 5. Local Database — Isar

- Use **Isar** for all local persistence
- Every collection needs `@collection` annotation
- `shared_preferences` only for: `isOnboarded` (bool)
- All Isar operations inside repository classes — never called from providers or UI directly
- Every synced collection must include `bool isSynced = false` and `DateTime createdAt`

---

## 6. Backend — Supabase

> ⚠️ **V3 DECISION: Supabase integration is DEFERRED.**
> All features must be complete, tested on real Android devices, and stable before
> any Supabase integration work begins. `SyncService` file exists but is a stub only.

### Current Phase (Feature Development)
- All data stays in Isar only
- `SyncService.pushUnsyncedRecords()` is a no-op stub — does nothing, logs a message
- `signInAnonymously()` is NOT called during this phase
- `isSynced` fields are still written to Isar (to avoid schema changes later)
- No Supabase client calls anywhere in the codebase during this phase

### Future Phase (Supabase Integration — after all features stable)
- Enable `SyncService` to push Isar records to Supabase
- Auth session fallback: check `currentSession` before any write, call `signInAnonymously()` if null
- Upsert strategy:
  - `users` table: `.upsert()` on `local_user_id`
  - `daily_summaries`: `.upsert(onConflict: 'user_id,date')`
  - `hydration_logs`: `.insert()` — each row is unique
  - `reminder_responses`: `.insert()` — each row is unique
- RLS: researcher bypasses via service role key — no user-facing RLS during research period

### What Agent Must NOT Do During Feature Phase
- Never call any Supabase method except in `sync_service.dart`
- Never configure Supabase client outside `main.dart` initialization
- Never block UI or app startup waiting for Supabase

---

## 7. Reminder System Rules

- `ReminderService.initialize()` called immediately after profile confirmation — NOT after first log
- Dynamic 3-tier logic (see ARCHITECTURE_V3.md section 4)
- Recalculate after every log and every app open
- Use `AndroidScheduleMode.exactAllowWhileIdle`
- Never schedule notifications if `notificationPermissionGranted: false`
- On every app open: rebuild notification schedule unconditionally
- Assume all pending notifications are dead on app open — reschedule if needed

### ⚠️ User-Configurable Reminder Window (V3)

Reminder window is set by user during profile setup and editable in Settings.

**Constraints (enforced in UI and service layer):**
```
Minimum start time : 06:00
Maximum end time   : 22:00
Minimum window     : 8 hours (end - start >= 8h)
Rationale          : Minimum 8 hours sleep for adolescents (target audience 13–18)
```

**Examples of valid windows:**
- 06:00–14:00 (8h — minimum)
- 07:00–21:00 (14h — default)
- 08:00–22:00 (14h)
- 06:00–22:00 (16h — maximum)

**Examples of invalid windows:**
- 06:00–13:00 (7h — below minimum)
- 05:00–21:00 (start before 06:00)
- 07:00–23:00 (end after 22:00)

**Stored in `UserProfile`:**
- `reminderWindowStart`: `int` — hour only (e.g., `7` for 07:00)
- `reminderWindowEnd`: `int` — hour only (e.g., `21` for 21:00)
- Default: start = `7`, end = `21`

### ⚠️ `remindersSent` Counter
Incremented in `ReminderService` at the moment a notification is **scheduled**, not when fired. Fired status is unreliable on aggressive OEM devices.

### ⚠️ `no_response` Lazy Detection (V3)
Real-time background detection is not reliable on Android. Use lazy detection on app open:

```dart
// On every app open, after _loadToday():
// Check all ReminderResponses for today where actionUsed is null
// and timestamp is > 60 minutes ago → mark as no_response
Future<void> _detectNoResponses() async {
  final pending = await reminderResponseRepository
      .getPendingResponses(userId); // actionUsed == null
  final cutoff = DateTime.now().subtract(const Duration(minutes: 60));
  for (final r in pending) {
    if (r.timestamp.isBefore(cutoff)) {
      await reminderResponseRepository.markNoResponse(r.id);
      // update DailySummary.remindersResponded is NOT incremented for no_response
    }
  }
}
```

**ReminderResponse is created when notification is scheduled (actionUsed: null).**
It is updated when user responds (actionUsed set) or when lazy detection runs (actionUsed: 'no_response').

---

## 8. Research Variable Rules

These variables MUST be captured — they are research data, not optional:
- `notificationPermissionGranted` — captured at onboarding
- `targetDiterima` + `targetManualMl` — captured at profile confirmation
- `loggedVia` — on every hydration log (`'app'` or `'notification_action'`)
- `actionUsed` — on every reminder response
- `sessionCount` — incremented on every app open, persisted in DailySummary
- `firstLogTimestamp` — first log of each day
- `dropoutFlag` — detected via date comparison on app open, set if gap > 3 days on **BOTH** `UserProfile` AND `DailySummary`
- `dropoutNotificationSent` — one-time flag, prevents duplicate re-engagement notifications
- `streakBreakHour` — hour of last log on days streak is broken
- `reminderWindowStart` + `reminderWindowEnd` — user's chosen reminder window (research variable)

If agent is about to implement any of these features without capturing these variables, STOP and add them first.

---

## 9. Dart Code Conventions

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables & functions: `camelCase`
- Constants: `kCamelCase`
- Private members: `_leadingUnderscore`

### Null Safety
- Never use `!` without a null check guard above it
- Prefer `??` and `?.` operators
- All model fields explicitly nullable or non-nullable

### Performance
- `const` constructors wherever possible
- Never call heavy computation inside `build()`
- All business logic in providers or services

### Immutability
- All model classes: `final` fields + `copyWith()` pattern

---

## 10. Navigation — go_router

- `go_router` exclusively — never `Navigator.push()` directly
- All routes in `app_router.dart`
- Route name constants in `app_constants.dart`

---

## 11. Package Constraints

### Approved Packages
| Purpose | Package |
|---|---|
| State Management | flutter_riverpod |
| Local DB | isar + isar_flutter_libs |
| Backend (deferred) | supabase_flutter |
| Notifications | flutter_local_notifications |
| Timezone | timezone |
| Charts | fl_chart |
| Progress UI | percent_indicator |
| Permissions | permission_handler |
| Onboarding | smooth_page_indicator |
| Navigation | go_router |

### Prohibited
- `get` / `GetX` — never
- `provider` (legacy) — never
- `hive` — use Isar
- `csv`, `share_plus`, `path_provider` — removed, no export
- `connectivity_plus` — not needed
- Any unlisted package requires explicit approval

---

## 12. Error Handling

- Never bare `catch (e)` without logging
- All async repository operations use typed exceptions
- UI handles loading, error, and empty states explicitly
- Sync failures are silent — log to console only (data safe in Isar)

---

## 13. What Agent Must Never Do

- Never run `flutter pub upgrade` — only `flutter pub get`
- Never delete or rename files without showing diff and getting approval
- Never add Firebase — Supabase only
- Never generate placeholder UI — all UI must be functional
- Never mix business logic into `build()` methods
- Never implement manual submit button — sync is automatic
- Never skip research variable capture (section 8) when implementing relevant features
- Never fetch education content from network — all content hardcoded in `app_constants.dart`
- Never attempt to write or generate content for `kHydrationArticles` — researcher provides content
- Never perform data mutations inside `HydrationNotifier._loadToday()` — it is READ-ONLY
- Never call Supabase methods outside `sync_service.dart` during feature development phase
- Never schedule notifications outside 06:00–22:00 window
- Never allow reminder window shorter than 8 hours

---

## 14. Scope Boundary

### Phase 1 — Feature Development (current)
All features built and tested with Isar only. No Supabase calls.
```
1.  Project Setup & Theme
2.  Splash & Navigation Guard
3.  Onboarding
4.  Profile Setup + Calculator
5.  Daily Dashboard
6.  Hydration Logging
7.  Reminder System
8.  Direct Action Notification
9.  Reminder Response Tracker
10. Education Screen
11. Settings Screen (reminder window, profile edit)
12. History Screen (riwayat beberapa hari dari Isar)
```

### Phase 2 — Supabase Integration (after Phase 1 stable)
- Enable SyncService
- Setup Supabase project + run schema migration
- Test sync end-to-end on real devices
- Researcher data access via Supabase dashboard

### Phase 3 — Nice to Have
- Gamification + Streak (F-11)
- Progress Screen charts (F-12)

### Out of Scope Entirely
- CSV export from app
- Admin panel or CMS
- Dynamic/network-fetched education content
- Photo profile
- UI animations beyond functional feedback

---

## 15. Isar Model Definitions (Canonical)

All Isar collections must match these schemas exactly. Do not add or remove fields without approval.

```dart
// UserProfile
@collection
class UserProfile {
  Id id = Isar.autoIncrement;
  late String userId;                    // UUID v4, generated once at profile setup
  // nama intentionally excluded — not stored (privacy)
  late DateTime tanggalLahir;            // age derived at runtime
  late String jenisKelamin;             // 'laki_laki' | 'perempuan'
  late double beratBadan;               // kg
  late String levelAktivitas;           // 'rendah'|'ringan'|'sedang'|'aktif'|'sangat_aktif'
  late String letakGeografis;           // 'dataran_rendah' | 'dataran_tinggi'
  List<String> riwayatPenyakit = [];    // multi-select, research variable, not used in calc
  late int dailyTargetMl;
  late bool targetDiterima;
  int? targetManualMl;
  late bool notificationPermissionGranted;
  late bool reminderSystemActive;
  int reminderWindowStart = 7;          // NEW V3 — hour (06–22, default 7)
  int reminderWindowEnd = 21;           // NEW V3 — hour (06–22, default 21, min 8h gap)
  late DateTime createdAt;
  DateTime? lastOpenedAt;
  bool dropoutFlag = false;
  bool dropoutNotificationSent = false; // NEW V3 — one-time re-engagement flag
  int currentStreak = 0;                // NEW V3 — used in Phase 3 gamification
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
  String? actionUsed;           // 'button_250'|'button_500'|'opened_app'|'no_response'|null (pending)
  late DateTime notificationScheduledAt; // NEW V3 — when notification was scheduled
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
  late double complianceRate;
  late int remindersSent;
  late int remindersResponded;
  late int sessionCount;
  late bool streakMaintained;
  DateTime? firstLogTimestamp;
  int? streakBreakHour;
  bool dropoutFlag = false;
  bool isSynced = false;
  late DateTime createdAt;
}
```

### DailySummary Upsert Pattern (canonical)
```dart
Future<void> upsertDailySummary(String userId, DateTime date, {
  required int achievedMl,
  required int targetMl,
  int? incrementRemindersResponded,
}) async {
  final existing = await _isar.dailySummarys
      .filter()
      .userIdEqualTo(userId)
      .dateEqualTo(date)
      .findFirst();

  if (existing != null) {
    final updated = existing.copyWith(
      achievedMl: achievedMl,
      complianceRate: achievedMl / existing.targetMl,
      remindersResponded: incrementRemindersResponded != null
          ? existing.remindersResponded + incrementRemindersResponded
          : existing.remindersResponded,
      isSynced: false,
    );
    await _isar.writeTxn(() async => _isar.dailySummarys.put(updated));
  } else {
    final summary = DailySummary()
      ..userId = userId
      ..date = date
      ..targetMl = targetMl
      ..achievedMl = achievedMl
      ..complianceRate = achievedMl / targetMl
      ..remindersSent = 0
      ..remindersResponded = 0
      ..sessionCount = 1
      ..streakMaintained = false
      ..dropoutFlag = false
      ..isSynced = false
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.dailySummarys.put(summary));
  }
}
```

---

## 16. Splash Startup Sequence (Strictly Sequential)

```dart
// All steps MUST be awaited before context.go('/dashboard')
// HydrationNotifier._loadToday() is READ-ONLY — no mutations allowed there

// Step 1: Midnight reset check
final profile = await profileRepo.getUserProfile();
if (profile != null && profile.lastOpenedAt != null) {
  if (!_isSameDay(profile.lastOpenedAt!, DateTime.now())) {
    await performMidnightReset(profile);
  }
}

// Step 2: Update lastOpenedAt (AFTER reset — order is critical)
await profileRepo.updateLastOpenedAt(DateTime.now());

// Step 3: Increment sessionCount in today's DailySummary
await dailySummaryRepo.incrementSessionCount(profile?.userId, DateTime.now());

// Step 4: Lazy no_response detection
await reminderResponseRepo.detectAndMarkNoResponses(
  userId: profile?.userId,
  cutoffMinutes: 60,
);

// Step 5: Dropout check
if (profile?.lastOpenedAt != null) {
  final gap = DateTime.now().difference(profile!.lastOpenedAt!).inDays;
  if (gap > 3) {
    await profileRepo.setDropoutFlag(true);
    await dailySummaryRepo.setDropoutFlag(profile.userId, DateTime.now(), true);
    if (!profile.dropoutNotificationSent) {
      // Schedule re-engagement notification (requires F-06 to be complete)
      await reminderService.scheduleReEngagementNotification();
      await profileRepo.setDropoutNotificationSent(true);
    }
  }
}

// Step 6: Navigate
context.go('/dashboard');

// Step 7 & 8: Fire-and-forget (non-blocking, AFTER navigation)
syncService.pushUnsyncedRecords(); // no-op stub during feature phase
reminderService.rescheduleIfNeeded();
```

### `performMidnightReset()` Sequence
```dart
Future<void> performMidnightReset(UserProfile profile) async {
  // 1. Finalize yesterday's DailySummary (complianceRate, streakMaintained)
  // 2. Update currentStreak in UserProfile
  // 3. Record streakBreakHour if streak broke
  // 4. Award achievements if Phase 3 active (skip for now)
  // 5. Reset daily hydration state to 0 in provider
  // 6. Cancel all pending notifications
  // 7. Schedule first reminder for today at reminderWindowStart
}
```

---

## 17. Reminder Window Validation

```dart
// Location: core/utils/date_utils.dart

static bool isValidReminderWindow(int startHour, int endHour) {
  if (startHour < 6 || startHour > 22) return false;
  if (endHour < 6 || endHour > 22) return false;
  if (endHour - startHour < 8) return false; // minimum 8 hours
  return true;
}

// Valid range examples:
// isValidReminderWindow(7, 21) → true  (14h window, default)
// isValidReminderWindow(6, 14) → true  (8h minimum)
// isValidReminderWindow(6, 13) → false (7h, below minimum)
// isValidReminderWindow(5, 21) → false (start before 06:00)
// isValidReminderWindow(7, 23) → false (end after 22:00)
```

---

## 18. Supabase Integration Phase (Deferred)

> Do not implement until instructed. This section documents what will be done, not what is active now.

**When integration begins:**
1. Create Supabase project
2. Run schema migration (see ARCHITECTURE_V3.md Section 10)
3. Enable `SyncService` — remove no-op stub
4. Add auth session fallback in `pushUnsyncedRecords()`
5. Test sync on real Android devices
6. Verify `nama` never appears in any Supabase payload
7. Researcher accesses data via Supabase dashboard SQL queries

## Gradle / Android Build Rules

- Do not run Gradle commands unless explicitly requested.
- Do not run `./gradlew build`, `./gradlew assembleDebug`, `./gradlew test`, or `flutter run` automatically.
- Before running any Gradle-related command, explain why it is necessary.
- Prefer static code inspection before build execution.
- If validation is needed, ask before running build commands.
- Never run multiple Gradle commands in parallel.
- After any Gradle command, run `./gradlew --stop` if no further build is needed.