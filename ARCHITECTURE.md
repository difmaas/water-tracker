# ARCHITECTURE.md
# Technical Architecture — Personal Hydration Tracker

---

## 1. Architectural Pattern

**Offline-First + Feature-Based Clean Architecture**

```
UI Layer (Presentation)
    ↕ Riverpod Providers
Domain Layer (Business Logic & Services)
    ↕ Repository Interface
Data Layer (Isar local + Supabase remote)
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
            └── gamificationProvider (Phase 2 only)
                    └── achievementRepository
```

> Note: `authProvider` removed. user_id is a local UUID — no auth state needed at provider level.

---

## 3. Sync Architecture (Revised)

### Core Principle
All writes go to Isar immediately. Supabase is populated automatically and silently on every app open. No user action required.

### Write Flow (Daily Usage)
```
User logs water / reminder responded
    ↓
Record saved to Isar with isSynced: false
    ↓
UI updates immediately
```

### Auto-Sync Flow (Every App Open)
```
App opens
    ↓
SyncService.pushUnsyncedRecords() called (fire and forget)
    ↓
Read all Isar records where isSynced: false
    ↓
Push to Supabase in order:
  user profile → hydration_logs → reminder_responses → daily_summaries
    ↓
On success: mark isSynced: true (per collection, independently)
On failure: silent — log to console, retry next app open
            data never lost (still in Isar)
```

### SyncService Responsibilities
- Called on every app open, after midnight reset check, before UI renders
- Each collection syncs independently — partial failure does not affect successful collections
- Never blocks UI — runs async in background
- Never exposes Supabase client to UI or providers

### Isar Models — Sync Flag Pattern
Every synced collection includes:
```dart
bool isSynced = false;
DateTime createdAt; // device-local timestamp, canonical
```

### Isar Init Failure
If Isar fails to initialize on cold start, app shows full-screen error and blocks all navigation. Never proceed with null Isar instance.

### Researcher Data Access
- Researcher queries all data directly from Supabase dashboard
- No in-app CSV export needed
- Admin query example:
```sql
SELECT
  ds.user_id, ds.date, ds.target_ml, ds.achieved_ml,
  ds.compliance_rate, ds.reminders_sent, ds.reminders_responded,
  ds.session_count, ds.streak_maintained, ds.dropout_flag,
  u.notification_permission_granted, u.activity_level,
  u.target_accepted
FROM daily_summaries ds
JOIN users u ON ds.user_id = u.id
ORDER BY ds.user_id, ds.date;
```

---

## 4. Reminder Architecture

### Trigger Point
Reminder system initializes immediately after profile setup is complete — NOT after first hydration log.

```
User confirms hydration target (end of F-03)
    ↓
ReminderService.initialize(targetMl: dailyTargetMl)
    ↓
Check current time against reminder window (default 07:00–21:00)
    ├── WITHIN window  → schedule first reminder 60 min from now
    └── OUTSIDE window → schedule first reminder tomorrow at 07:00
```

### Dynamic Reminder Logic (3-Tier)
```
After every hydration log OR app open:
    ↓
Calculate progress = currentMl / targetMl

progress < 40%   → remind every 60 minutes
progress 40-80%  → remind every 90 minutes
progress > 80%   → cancel all pending notifications
target reached   → cancel all + show celebration
```

### Boot Recovery (Critical)
On every app open, `ReminderService.rescheduleIfNeeded()` runs unconditionally — assumes all previously scheduled notifications may have been killed by device reboot or OEM process killer.

```
App open
    ↓
ReminderService.rescheduleIfNeeded()
    ↓
Check pending notification count
    ├── Pending exists → skip
    └── No pending + within window + progress < 80% → reschedule now
```

### Direct Action Notification
Every reminder notification includes inline action buttons:

```
💧 Waktunya minum air!
Progress hari ini: X% — Yml lagi menuju target
[expanded: random fun fact]

[ + 250ml ]  [ + 500ml ]  [ Buka App ]
```

- Tapping `+250ml` or `+500ml` logs directly via notification action
- Logs `ReminderResponse` with `completed: true`, `delayMinutes: 0`
- App UI syncs on next open via `hydrationProvider` refresh

### Reminder Window Rules
- Active hours: 07:00–21:00
- No notifications sent outside active hours
- If setup completed after 21:00: first reminder scheduled for next day 07:00
- Timezone: device local timezone only. No timezone switching support.

### Midnight Reset
Triggered by lazy date comparison on app open — NOT by a scheduled background job.

```dart
void performMidnightReset() {
  // 1. Finalize DailySummary for yesterday (complianceRate, streakMaintained)
  // 2. Update streak in UserProfile
  // 3. Check and award achievements (Phase 2 only)
  // 4. Reset daily hydration state to 0
  // 5. Cancel all pending notifications
  // 6. Schedule first reminder for today at 07:00
}
```

### Android-Specific Requirements
- `AndroidScheduleMode.exactAllowWhileIdle` for reliable delivery
- `SCHEDULE_EXACT_ALARM` permission (Android 12+)
- `POST_NOTIFICATIONS` permission (Android 13+)
- Show battery optimization whitelist dialog on first notification setup
- Notification permission status stored in Isar as research variable

---

## 5. Research Data Architecture

### Research Priority

| Variable | Collection Point | Priority | Notes |
|---|---|---|---|
| `notificationPermissionGranted` | Profile setup | **Critical** | Core independent variable |
| `loggedVia` | Every hydration log | **Critical** | App vs notification-triggered behavior |
| `reminderResponseDelayMinutes` | Every reminder | **Critical** | Learning effect over days |
| `complianceRate` | Daily summary | **Critical** | Primary dependent variable |
| `sessionCount` | Every app open | **Medium** | Engagement proxy |
| `firstLogTimestamp` | Daily | **Medium** | Early starter correlation |
| `targetAccepted` + `manualTargetMl` | Profile confirmation | **Medium** | Target ownership effect |
| `dropoutFlag` | App open check | **Medium** | Detected lazily, not background task |
| `streakBreakHour` | Midnight reset | **Low** | Nice to have for analysis |

### DailySummary Collection (Isar)
One record per user per day. Upserted (not inserted) on every hydration log and app open.

```dart
class DailySummary {
  late String userId;
  late DateTime date;
  late int targetMl;
  late int achievedMl;
  late double complianceRate;
  late int remindersSent;
  late int remindersResponded;
  late int sessionCount;          // incremented on app open for this date
  late bool streakMaintained;
  DateTime? firstLogTimestamp;
  int? streakBreakHour;
  bool dropoutFlag = false;
  bool isSynced = false;
  late DateTime createdAt;
}
```

### Dropout Detection
Detected lazily on app open — not via background scheduled task.

```
App open
    ↓
Compare DateTime.now() with UserProfile.lastOpenedAt
    ↓
Gap > 3 days?
    ├── YES → set dropoutFlag: true in UserProfile + today's DailySummary
    │         send one re-engagement notification (one-time only)
    └── NO  → continue normally
```

---

## 6. Hydration Calculation Engine

```dart
// Location: features/profile/domain/hydration_calculator.dart

class HydrationCalculatorService {
  static int calculate({
    required double weightKg,
    required String activityLevel,
  }) {
    const baseMultiplier = 35; // ml per kg
    final base = (weightKg * baseMultiplier).round();

    final adjustment = switch (activityLevel) {
      'sedentary'   => 0,
      'light'       => 300,
      'moderate'    => 500,
      'active'      => 700,
      'very_active' => 1000,
      _             => 0,
    };

    return (base + adjustment).clamp(1500, 4000);
  }
}
```

---

## 7. Education Content Architecture

### Design Decision
All education content is hardcoded as Dart constants. No CMS, no network calls, no admin panel. Content is fixed for the duration of the study period.

### Content Structure
```dart
// Location: core/constants/app_constants.dart

class HydrationArticle {
  final String id;
  final String title;
  final String summary;     // 1-2 sentences, shown on card
  final String body;        // full article, shown on detail screen
  final String category;    // 'manfaat' | 'mitos' | 'tips' | 'sains'
  final String emoji;       // visual identifier on card

  const HydrationArticle({...});
}

const List<HydrationArticle> kHydrationArticles = [
  HydrationArticle(
    id: 'art_001',
    title: 'Kenapa 8 Gelas Sehari Itu Mitos?',
    summary: 'Angka 8 gelas tidak punya dasar ilmiah yang kuat. Kebutuhan air tiap orang berbeda.',
    body: '...full content...',
    category: 'mitos',
    emoji: '🔍',
  ),
  HydrationArticle(
    id: 'art_002',
    title: 'Dehidrasi Ringan Merusak Konsentrasi',
    summary: 'Kehilangan 1–2% cairan tubuh sudah cukup untuk menurunkan fokus dan suasana hati.',
    body: '...full content...',
    category: 'sains',
    emoji: '🧠',
  ),
  // ... 10-15 articles total
];
```

### Categories
- `mitos` — debunking common hydration myths
- `sains` — science-backed facts about water and the body
- `tips` — practical hydration habits
- `manfaat` — benefits of proper hydration

### Integration Points
- Education screen: scrollable card list, tap to open full article
- Dashboard: one random `kHydrationFacts` short fact shown per session
- Notifications: random fact in expanded notification text
- Onboarding page 1: one random fact displayed

### Fun Facts (Short Form)
Kept separately as `kHydrationFacts` — used for quick display only, not full articles.

```dart
const List<String> kHydrationFacts = [
  "Tubuh manusia terdiri dari sekitar 60% air.",
  "Dehidrasi ringan 1–2% sudah dapat menurunkan konsentrasi.",
  "Otak manusia mengandung sekitar 75% air.",
  "Air putih tidak mengandung kalori — minuman terbaik untuk hidrasi.",
  "Rasa haus muncul setelah tubuh sudah mulai dehidrasi.",
  "Minum air sebelum makan dapat membantu mengontrol porsi makan.",
  "Ginjal membutuhkan cukup air untuk menyaring limbah dari darah.",
  "Warna urin kuning pucat menandakan hidrasi yang baik.",
  "Kafein bersifat diuretik ringan — imbangi dengan air putih.",
  "Tubuh kehilangan air melalui napas, keringat, dan urin setiap hari.",
  "Sel otak sangat sensitif terhadap perubahan kadar air tubuh.",
  "Minum air dingin dapat membakar sedikit kalori untuk menghangatkannya.",
  "Otot yang terhidrasi dengan baik lebih tahan terhadap kram.",
  "Air membantu mengatur suhu tubuh melalui proses berkeringat.",
  "Konsumsi air yang cukup dapat membantu mencegah batu ginjal.",
];
```

---

## 8. Gamification Logic (Phase 2)

> Do not implement until Phase 1 is complete and stable.

### Streak Calculation
- Streak increments if daily compliance ≥ 80% at midnight reset
- Streak resets to 0 if compliance < 80%
- Record `streakBreakHour` when streak breaks

### Achievement Trigger Events
| Achievement | Trigger Condition |
|---|---|
| First Drop | First hydration log ever |
| 3 Day Streak | streak_count == 3 |
| 7 Day Streak | streak_count == 7 |
| Hydration Master | 30 consecutive days ≥ 80% |
| Perfect Day | 100% target reached in a single day |
| Early Bird | First log before 08:00 for 5 consecutive days |

---

## 10. Supabase Schema (Final)

```sql
-- users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  local_user_id TEXT UNIQUE NOT NULL,   -- UUID v4 from device
  gender TEXT NOT NULL,
  age INT NOT NULL,
  weight FLOAT NOT NULL,
  activity_level TEXT NOT NULL,
  daily_target_ml INT NOT NULL,
  target_accepted BOOLEAN NOT NULL,
  manual_target_ml INT,
  notification_permission_granted BOOLEAN NOT NULL,
  dropout_flag BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- hydration_logs
CREATE TABLE hydration_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(local_user_id),
  volume INT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  logged_via TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- reminder_responses
CREATE TABLE reminder_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT REFERENCES users(local_user_id),
  completed BOOLEAN NOT NULL,
  delay_minutes INT,
  action_used TEXT,
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
  reminders_sent INT NOT NULL,
  reminders_responded INT NOT NULL,
  session_count INT NOT NULL,
  streak_maintained BOOLEAN NOT NULL,
  first_log_timestamp TIMESTAMPTZ,
  dropout_flag BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);
```

### Row Level Security
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE hydration_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;

-- Users can insert and read their own data
CREATE POLICY "user_insert_own" ON hydration_logs
  FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id'));

-- Researcher/admin bypasses RLS via service role key
-- No in-app admin panel needed
```

---

## 11. Navigation Route Map

```
/ (splash)
├── /onboarding          (first launch only)
├── /profile-setup       (after onboarding)
└── /dashboard           (main screen)
    ├── /log             (bottom sheet)
    ├── /education       (article list + detail)
    ├── /progress        (Phase 2 — weekly chart + compliance)
    └── /achievements    (Phase 2 — badges screen)
```

> `/export` route removed. No in-app export.

---

## 12. Known Technical Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Background notification killed by OEM | High | Rebuild schedule unconditionally on every app open |
| Notification permission denied | High | Graceful degradation + research flag captured |
| Midnight reset missed (app not opened) | Medium | Lazy date comparison catches it on next open |
| Supabase sync failure | Low | Silent retry on next open — data safe in Isar |
| Device reboot clears scheduled notifications | High | Boot recovery in ReminderService |
| User never opens app again (dropout) | Medium | dropoutFlag set on next open if gap > 3 days |
| Isar schema migration on update | Low | Version schema from start |
| Sync race condition (duplicate records) | Medium | UNIQUE constraint on Supabase (user_id, date) |