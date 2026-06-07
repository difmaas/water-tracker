# Technical Architecture — Personal Hydration Tracker

> **V3 Changelog (2026-05-15):**
> - §3: Supabase integration deferred — SyncService is no-op stub during Phase 1
> - §4: Reminder window user-configurable (06:00–22:00, min 8h); stored in UserProfile
> - §4: ReminderResponse created at schedule time (actionUsed: null) for lazy no_response detection
> - §4: no_response detection is lazy — runs on app open, not real-time background
> - §5: dropoutNotificationSent flag added; dropout notification deferred until F-06 complete
> - §5: Dropout flags BOTH UserProfile AND DailySummary
> - §9: Supabase schema updated — aligned with F-03 refactor (tanggalLahir, letakGeografis, riwayatPenyakit); nama excluded; reminderWindowStart/End added
> - §9: RLS policy corrected — uses service role key for researcher, not current_setting()
> - §10: History screen data source defined
> - §12: Risk table updated

---

## 1. Architectural Pattern

**Offline-First + Feature-Based Clean Architecture**

```
UI Layer (Presentation)
    ↕ Riverpod Providers
Domain Layer (Business Logic & Services)
    ↕ Repository Interface
Data Layer (Isar local — Supabase remote deferred to Phase 2)
```

Each feature is self-contained. Dependencies only flow downward:

```
widgets → providers → services → repositories → storage
```

Reverse imports are forbidden. No widget may import a repository directly.

---

## 2. State Management Flow

```
User Action (tap, input)
    ↓
ConsumerWidget → calls Notifier method
    ↓
StateNotifier / AsyncNotifier
    ↓
Repository (data layer)
    ↓
Isar (write local first)
    ↓
State updated → UI rebuilds
```

### Provider Dependency Map

```
profileProvider
    └── hydrationProvider
            ├── loggingRepository
            ├── reminderProvider
            └── gamificationProvider (Phase 3 only)
                    └── achievementRepository
```

---

## 3. Sync Architecture

### Phase 1 — Isar Only (current)

All data lives in Isar. `SyncService` is a no-op stub:

```dart
// core/services/sync_service.dart — Phase 1 stub
class SyncService {
  Future<void> pushUnsyncedRecords() async {
    // Deferred — Supabase integration not active
    debugPrint('[SyncService] Sync deferred — Phase 1');
  }
}
```

`isSynced` fields are still written to Isar models so schema requires no changes in Phase 2.

### Phase 2 — Supabase Integration (after all features stable)

```
App opens
    ↓
SyncService.pushUnsyncedRecords() (fire and forget)
    ↓
Check auth.currentSession — if null: signInAnonymously()
    ↓
Read all Isar records where isSynced: false
    ↓
Push in order:
  UserProfile → HydrationLog → ReminderResponse → DailySummary
    ↓
Per collection: success → isSynced: true | failure → silent, retry next open
```

### Upsert Strategy (Phase 2)

| Table | Method | Conflict Key | Reason |
|---|---|---|---|
| `users` | `.upsert()` | `local_user_id` | Profile editable, may re-sync |
| `daily_summaries` | `.upsert(onConflict: 'user_id,date')` | `(user_id, date)` | Updated multiple times per day |
| `hydration_logs` | `.insert()` | N/A | Each log is unique |
| `reminder_responses` | `.insert()` | N/A | Each response is unique |

### Sync Constraints (Phase 2)
- Max 500 records per sync session — oldest first if overflow
- Records older than 30 days: mark `isSynced: true` locally, skip push
- Each collection syncs independently — partial failure does not block others
- `nama` is NEVER included in any Supabase payload — excluded explicitly in SyncService

---

## 4. Reminder Architecture

### Trigger Point
Initialized immediately after profile setup — NOT after first log.

```
Profile confirmed (F-03)
    ↓
ReminderService.initialize(profile)
    ↓
Read reminderWindowStart, reminderWindowEnd from UserProfile
    ↓
Check current time against user's window
    ├── WITHIN window  → schedule first reminder 60 min from now
    └── OUTSIDE window → schedule first reminder tomorrow at reminderWindowStart:00
```

### User-Configurable Reminder Window (V3)

Window is set during profile setup (F-03) and editable in Settings (F-10).

```
Constraints:
  Minimum start : 06:00
  Maximum end   : 22:00
  Minimum gap   : 8 hours  (end - start ≥ 8)

Rationale: minimum 8 hours sleep for adolescent target audience (13–18 years)

Default: start = 7 (07:00), end = 21 (21:00)
Stored as int hours in UserProfile: reminderWindowStart, reminderWindowEnd
```

```dart
// Validation — core/utils/date_utils.dart
static bool isValidReminderWindow(int startHour, int endHour) {
  if (startHour < 6 || startHour > 22) return false;
  if (endHour < 6 || endHour > 22) return false;
  if (endHour - startHour < 8) return false;
  return true;
}
```

### Dynamic Reminder Logic (3-Tier)

```
After every hydration log OR app open:
    ↓
progress = currentMl / targetMl

progress < 40%   → remind every 60 min
progress 40–80%  → remind every 90 min
progress > 80%   → cancel all pending
target reached   → cancel all + celebration on dashboard
```

### ReminderResponse Lifecycle (V3)

ReminderResponse is created when a notification is **scheduled**, not when fired.
This enables lazy `no_response` detection without background tasks.

```
Notification scheduled
    ↓
Create ReminderResponse {
  actionUsed: null,               ← pending — not yet responded
  notificationScheduledAt: now,
  completed: false,
}
    ↓
User responds (one of):
  A. Opens app from notification  → actionUsed: 'opened_app', completed: true
  B. Taps +250ml button           → actionUsed: 'button_250', completed: true
  C. Taps +500ml button           → actionUsed: 'button_500', completed: true
  D. Logs within 30 min via app   → actionUsed: 'opened_app', completed: true
  E. No response (lazy detection) → actionUsed: 'no_response', completed: false
```

### No_Response Lazy Detection (V3)

Real-time background detection is unreliable on Android OEM devices.
Detection runs on every app open inside the Splash startup sequence.

```dart
// Step 4 of splash startup sequence
Future<void> detectAndMarkNoResponses({
  required String userId,
  int cutoffMinutes = 60,
}) async {
  final pending = await _isar.reminderResponses
      .filter()
      .userIdEqualTo(userId)
      .actionUsedIsNull()    // still pending
      .findAll();

  final cutoff = DateTime.now().subtract(Duration(minutes: cutoffMinutes));

  for (final r in pending) {
    if (r.notificationScheduledAt.isBefore(cutoff)) {
      final updated = r.copyWith(
        actionUsed: 'no_response',
        completed: false,
        delayMinutes: cutoffMinutes,
      );
      await _isar.writeTxn(() async => _isar.reminderResponses.put(updated));
      // NOTE: remindersResponded in DailySummary is NOT incremented for no_response
    }
  }
}
```

### Boot Recovery

On every app open, `ReminderService.rescheduleIfNeeded()` runs unconditionally.
Assumes all previously scheduled notifications may be dead (reboot, OEM process killer).

```
App open
    ↓
rescheduleIfNeeded()
    ↓
Check pending notification count
    ├── Pending exists → skip
    └── No pending + within window + progress < 80% → reschedule now
```

### Midnight Reset

Triggered by lazy date comparison on app open — NOT by a scheduled background job.

```
Splash Step 1:
    ↓
Read UserProfile.lastOpenedAt
    ↓
lastOpenedAt.day != DateTime.now().day?
    ├── YES → await performMidnightReset(profile)
    └── NO  → skip
```

```dart
Future<void> performMidnightReset(UserProfile profile) async {
  // 1. Finalize yesterday's DailySummary
  //    - set complianceRate = achievedMl / targetMl
  //    - set streakMaintained = complianceRate >= 0.8
  //    - if !streakMaintained: record streakBreakHour = hour of last log yesterday
  // 2. Update UserProfile.currentStreak
  //    - streakMaintained: currentStreak++
  //    - !streakMaintained: currentStreak = 0
  // 3. Award achievements if Phase 3 active (skip now)
  // 4. Reset daily hydration state in hydrationProvider to 0
  // 5. Cancel all pending notifications
  // 6. Schedule first reminder for today at reminderWindowStart:00
}
```

### Splash Startup Sequence (Strictly Sequential)

```
Step 1: await performMidnightReset() if new day
Step 2: await updateLastOpenedAt(DateTime.now())
Step 3: await incrementSessionCount(userId, today)
Step 4: await detectAndMarkNoResponses(userId)
Step 5: await checkDropout(profile)
Step 6: context.go('/dashboard')
Step 7: fire-and-forget SyncService.pushUnsyncedRecords()  ← no-op in Phase 1
Step 8: fire-and-forget ReminderService.rescheduleIfNeeded()
```

> ⚠️ `HydrationNotifier._loadToday()` is READ-ONLY.
> It reads today's logs and profile, updates display state only.
> It MUST NOT perform midnight reset, update `lastOpenedAt`, increment `sessionCount`,
> or run dropout detection. All mutations are in the Splash sequence above.

### Direct Action Notification

```
💧 Waktunya minum air!
Progress hari ini: X% — Yml lagi menuju target
[expanded: random kHydrationFacts]

[ +250ml ]  [ +500ml ]  [ Buka App ]
```

### Android-Specific Requirements
- `AndroidScheduleMode.exactAllowWhileIdle`
- `SCHEDULE_EXACT_ALARM` permission (Android 12+)
- `POST_NOTIFICATIONS` permission (Android 13+)
- Battery optimization whitelist dialog on first setup

---

## 5. Research Data Architecture

### Research Priority

| Variable | Collection Point | Priority | Notes |
|---|---|---|---|
| `notificationPermissionGranted` | Onboarding | **Critical** | Core independent variable |
| `loggedVia` | Every log | **Critical** | App vs notification behavior |
| `reminderResponseDelayMinutes` | Every reminder | **Critical** | Learning effect over days |
| `complianceRate` | Daily summary | **Critical** | Primary dependent variable |
| `reminderWindowStart/End` | Profile setup | **High** | Does custom window affect compliance? |
| `sessionCount` | Every app open | **Medium** | Engagement proxy |
| `firstLogTimestamp` | Daily | **Medium** | Early starter correlation |
| `targetDiterima` + `targetManualMl` | Profile confirmation | **Medium** | Target ownership effect |
| `letakGeografis` | Profile setup | **Medium** | Geographic modifier effect |
| `dropoutFlag` | App open check | **Medium** | Detected lazily |
| `dropoutNotificationSent` | Dropout detection | **Medium** | Prevents duplicate notifications |
| `streakBreakHour` | Midnight reset | **Low** | Nice to have |

### DailySummary Collection (Isar)

One record per user per day. Upserted on every hydration log and app open.

```dart
class DailySummary {
  late String userId;
  late DateTime date;
  late int targetMl;
  late int achievedMl;
  late double complianceRate;
  late int remindersSent;        // incremented when notification scheduled
  late int remindersResponded;   // incremented when completed: true only
  late int sessionCount;
  late bool streakMaintained;
  DateTime? firstLogTimestamp;
  int? streakBreakHour;
  bool dropoutFlag = false;
  bool isSynced = false;
  late DateTime createdAt;
}
```

### Dropout Detection

```
Splash Step 5:
    ↓
gap = DateTime.now().difference(lastOpenedAt).inDays
    ↓
gap > 3?
    ├── YES → setDropoutFlag(true) on UserProfile
    │         setDropoutFlag(true) on today's DailySummary
    │         if dropoutNotificationSent == false:
    │           scheduleReEngagementNotification()  ← requires F-06
    │           setDropoutNotificationSent(true)
    └── NO  → continue
```

> **Note:** Re-engagement notification requires `flutter_local_notifications` to be
> initialized (F-06). If dropout is detected before F-06, flags are set but notification
> is skipped silently. `dropoutNotificationSent` remains false until notification is sent.

---

## 6. Hydration Calculation Engine

Modifier-based architecture. Formula finalized with nakes consultation — currently using general baseline.

```dart
// features/profile/domain/hydration_calculator.dart

class HydrationCalculatorService {
  static int calculate(UserProfile profile) {
    double result = _base(profile.beratBadan);
    for (final modifier in _modifiers) {
      result = modifier(result, profile);
    }
    return result.round().clamp(1500, 4000);
  }

  static double _base(double weightKg) => weightKg * 35; // EFSA 2010 baseline

  static final _modifiers = [
    _activityModifier,
    _genderModifier,
    _geographicModifier,
    // _medicalModifier — reserved, not active until nakes consultation complete
  ];
}

// Modifier values — extracted to constants for future configurability
// core/constants/app_constants.dart
const kActivityModifiers = {
  'rendah': 0, 'ringan': 300, 'sedang': 500, 'aktif': 700, 'sangat_aktif': 1000,
};
const kGenderModifier = {'laki_laki': 0, 'perempuan': -200};
const kGeographicModifier = {'dataran_rendah': 0, 'dataran_tinggi': 200};
```

**Disclaimer (required on all confirmation screens):**
> "Estimasi kebutuhan cairan harian berdasarkan data profil pengguna.
> Bukan penggantian saran medis profesional."

---

## 7. Education Content Architecture

All content hardcoded in `app_constants.dart`. No CMS, no network, no admin panel.

```dart
class HydrationArticle {
  final String id;
  final String title;
  final String summary;   // shown on card
  final String body;      // shown on detail screen
  final String category;  // 'manfaat' | 'mitos' | 'tips' | 'sains'
  final String emoji;
}
```

Content provided by researcher — agent must NOT generate article content.

---

## 8. History Screen Data Architecture

History screen reads from Isar only — never Supabase.

```
History Screen
    ↓
Read DailySummary records for last N days (default 7)
    ↓
For each day tapped: read HydrationLog records for that date
    ↓
Display: date, achievedMl/targetMl, complianceRate, dropoutFlag indicator
```

**Data availability:** DailySummary for a day is finalized during `performMidnightReset()` on the following app open. Today's record is shown as "sedang berjalan" (in progress) — not finalized.

---

## 9. Supabase Schema (Phase 2 — not active in Phase 1)

```sql
-- users (aligned with F-03 refactor — V3)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  local_user_id TEXT UNIQUE NOT NULL,
  -- nama intentionally excluded — never stored
  tanggal_lahir DATE NOT NULL,
  jenis_kelamin TEXT NOT NULL,          -- 'laki_laki' | 'perempuan'
  berat_badan FLOAT NOT NULL,
  level_aktivitas TEXT NOT NULL,
  letak_geografis TEXT NOT NULL,        -- 'dataran_rendah' | 'dataran_tinggi'
  riwayat_penyakit TEXT[] DEFAULT '{}', -- research variable only
  daily_target_ml INT NOT NULL,
  target_diterima BOOLEAN NOT NULL,
  target_manual_ml INT,
  notification_permission_granted BOOLEAN NOT NULL,
  reminder_window_start INT NOT NULL DEFAULT 7,
  reminder_window_end INT NOT NULL DEFAULT 21,
  dropout_flag BOOLEAN DEFAULT FALSE,
  dropout_notification_sent BOOLEAN DEFAULT FALSE,
  current_streak INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- hydration_logs
CREATE TABLE hydration_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(local_user_id),
  volume INT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  logged_via TEXT NOT NULL,             -- 'app' | 'notification_action'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- reminder_responses
CREATE TABLE reminder_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(local_user_id),
  completed BOOLEAN NOT NULL,
  delay_minutes INT,
  action_used TEXT,                     -- 'button_250'|'button_500'|'opened_app'|'no_response'|null
  notification_scheduled_at TIMESTAMPTZ NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- daily_summaries
CREATE TABLE daily_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(local_user_id),
  date DATE NOT NULL,
  target_ml INT NOT NULL,
  achieved_ml INT NOT NULL,
  compliance_rate FLOAT NOT NULL,
  reminders_sent INT NOT NULL DEFAULT 0,
  reminders_responded INT NOT NULL DEFAULT 0,
  session_count INT NOT NULL DEFAULT 0,
  streak_maintained BOOLEAN NOT NULL DEFAULT FALSE,
  first_log_timestamp TIMESTAMPTZ,
  streak_break_hour INT,
  dropout_flag BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);
```

### Row Level Security (Phase 2)

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE hydration_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;

-- App users: insert and select own data via anon key
CREATE POLICY "users_own_data" ON users
  FOR ALL USING (local_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Researcher: full access via service role key (bypasses RLS automatically)
-- No additional policy needed for researcher access
-- Researcher connects via Supabase dashboard or psql with service role key
```

### Researcher Admin Query Example

```sql
SELECT
  ds.user_id,
  ds.date,
  ds.target_ml,
  ds.achieved_ml,
  ds.compliance_rate,
  ds.reminders_sent,
  ds.reminders_responded,
  ds.session_count,
  ds.dropout_flag,
  u.notification_permission_granted,
  u.level_aktivitas,
  u.letak_geografis,
  u.reminder_window_start,
  u.reminder_window_end,
  u.target_diterima,
  u.riwayat_penyakit
FROM daily_summaries ds
JOIN users u ON ds.user_id = u.local_user_id
ORDER BY ds.user_id, ds.date;
```

---

## 10. Navigation Route Map

```
/ (splash)
├── /onboarding
├── /profile-setup
└── /dashboard                    ← Tab 1
    ├── Bottom Nav Tab 2: /log    ← logging + today's list
    ├── Bottom Nav Tab 3: /education
    │   └── /education/:id
    ├── Bottom Nav Tab 4: /history
    └── Bottom Nav Tab 5: /settings
        └── /profile-edit         ← re-uses F-03 form
```

---

## 11. Gamification Logic (Phase 3 Only)

> Do not implement until Phase 2 (Supabase integration) is complete and stable.

### Streak Calculation
- Uses `UserProfile.currentStreak` (already in schema)
- Increments in `performMidnightReset()` if `complianceRate >= 0.8`
- Resets to 0 if compliance < 80%; record `streakBreakHour`

### Achievement Trigger Events
| Achievement | Trigger |
|---|---|
| First Drop | First hydration log ever |
| 3 Day Streak | currentStreak == 3 |
| 7 Day Streak | currentStreak == 7 |
| Perfect Day | 100% target in one day |
| Early Bird | First log before 08:00 for 5 consecutive days |

---

## 12. Known Technical Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Background notification killed by OEM | High | Rebuild schedule unconditionally on every app open |
| Notification permission denied | High | Graceful degradation + research flag captured |
| Midnight reset missed (app not opened) | Medium | Lazy date comparison catches it on next open |
| Splash → Dashboard race condition | High | Sequential `await` chain before navigation (V2 fix) |
| `no_response` not detected in real-time | Medium | Lazy detection on app open — acceptable for research |
| ReminderResponse created before notification fires | Low | Intentional — enables lazy detection pattern |
| Reminder window set too narrow by user | Low | 8-hour minimum enforced in UI + service layer |
| Device reboot clears scheduled notifications | High | Boot recovery in `rescheduleIfNeeded()` |
| Isar schema migration after distribution | High | Schema finalized before distributing to respondents |
| Supabase sync failure (Phase 2) | Low | Silent retry — data safe in Isar |
| `nama` accidentally synced to Supabase | High | Explicit exclusion in SyncService + verified before Phase 2 |
| Duplicate dropout notification | Medium | `dropoutNotificationSent` flag prevents repeat |
| Offline first-launch → no auth session (Phase 2) | Medium | Auth session fallback in SyncService |