# Feature Specifications & Acceptance Criteria
# Personal Hydration Tracker

> **V3 Changelog (2026-05-15):**
> - Supabase integration deferred to Phase 2 — all F-10 Supabase calls are stubs
> - F-00: `no_response` lazy detection added to startup sequence
> - F-00: `dropoutNotificationSent` flag added to prevent duplicate re-engagement
> - F-03: Schema aligned with refactored profile fields
> - F-06: Reminder window now user-configurable (stored in UserProfile)
> - F-06: Reminder window constraints — min 8h, 06:00–22:00
> - F-11 (new): Settings Screen
> - F-12 (new): History Screen (riwayat beberapa hari)
> - Phase numbering updated

---

## Build Order

### Phase 1 — Feature Development (Isar only, no Supabase)
```
1.  Project Setup & Theme          (F-01)
2.  Splash & Navigation Guard      (F-00)
3.  Onboarding                     (F-02)
4.  Profile Setup + Calculator     (F-03)
5.  Daily Dashboard                (F-04)
6.  Hydration Logging              (F-05)
7.  Reminder System                (F-06)
8.  Direct Action Notification     (F-07)
9.  Reminder Response Tracker      (F-08)
10. Education Screen               (F-09)
11. Settings Screen                (F-10)
12. History Screen                 (F-11)
```

### Phase 2 — Supabase Integration (after Phase 1 stable on real device)
```
13. Auto-sync to Supabase          (F-12)
```

### Phase 3 — Nice to Have
```
14. Gamification + Streak          (F-13)
15. Progress Screen                (F-14)
```

---

## PHASE 1 — FEATURE DEVELOPMENT

---

### F-01: Project Setup & Theme

**Acceptance Criteria:**
- [ ] `flutter create` with package name `com.research.hydration_tracker`
- [ ] All packages in AGENTS_V3.md installed in `pubspec.yaml`
- [ ] `AppTheme`, `AppColors`, `AppTypography` defined in `app/theme/`
- [ ] Primary color: `#1A73E8`, background: white, accent: `#E8F0FE`
- [ ] `go_router` configured, all routes stubbed
- [ ] `main.dart` wraps app in `ProviderScope`
- [ ] `kHydrationFacts` (15 facts) and `kHydrationArticles` template in `app_constants.dart`
- [ ] App runs on Android without errors

---

### F-00: Splash Screen & Navigation Guard

**Acceptance Criteria:**
- [ ] Splash screen first route (`/`) — shows app logo ~1.5 seconds
- [ ] Read `isOnboarded` from `shared_preferences`
  - `false` → `/onboarding`
  - `true` → query Isar for `UserProfile`
    - exists → `/dashboard`
    - missing → `/profile-setup`
- [ ] No `Navigator.push()` — use `go_router` redirect

**Startup Sequence (strictly sequential — all `await`ed before navigation):**

- [ ] **Step 1:** Check `lastOpenedAt` vs today. If different day → `await performMidnightReset()`
- [ ] **Step 2:** `await` update `UserProfile.lastOpenedAt = DateTime.now()`
- [ ] **Step 3:** `await` increment `sessionCount` in today's `DailySummary`
- [ ] **Step 4:** `await` lazy `no_response` detection — mark ReminderResponses where `actionUsed == null` and `notificationScheduledAt` is > 60 min ago as `actionUsed: 'no_response'`
- [ ] **Step 5:** `await` dropout check — if gap > 3 days: set `dropoutFlag: true` on BOTH `UserProfile` AND today's `DailySummary`. If `dropoutNotificationSent == false`: schedule re-engagement notification AND set `dropoutNotificationSent: true`
- [ ] **Step 6:** `context.go('/dashboard')`
- [ ] **Step 7 (fire-and-forget):** `SyncService.pushUnsyncedRecords()` — no-op stub in Phase 1
- [ ] **Step 8 (fire-and-forget):** `ReminderService.rescheduleIfNeeded()`

---

### F-02: Onboarding

**Acceptance Criteria:**
- [ ] 3-page onboarding using `smooth_page_indicator`
- [ ] Page 1: App intro + research purpose + random `kHydrationFacts`
- [ ] Page 2: Flow visual: profil → target → pengingat → log → edukasi
- [ ] Page 3: Notification permission request via `permission_handler`
- [ ] Permission stored in `UserProfile.notificationPermissionGranted`
- [ ] If denied: allow skip, show persistent banner on dashboard
- [ ] On complete: write `isOnboarded: true` to `shared_preferences`
- [ ] Skip option on page 1 — defaults `notificationPermissionGranted: false`

---

### F-03: User Profile Setup + Hydration Calculator

**Acceptance Criteria:**
- [ ] Form fields (all required except `riwayatPenyakit`):
  - Tanggal Lahir — date picker, age derived must be valid (app accepts any age)
  - Jenis Kelamin — dropdown: Laki-laki / Perempuan
  - Berat Badan — decimal, 20–200 kg
  - Level Aktivitas — dropdown: Rendah / Ringan / Sedang / Aktif / Sangat Aktif
  - Letak Geografis — dropdown: Dataran Rendah / Dataran Tinggi
  - Riwayat Penyakit — multi-select checklist (optional): Diabetes Mellitus, Gagal Ginjal, Penyakit Jantung, Penyakit Hati Sirosis
- [ ] Reminder window setup — time picker for start and end hour
  - Default: 07:00–21:00
  - Constraints: start ≥ 06:00, end ≤ 22:00, (end - start) ≥ 8 hours
  - Error: "Jendela pengingat minimal 8 jam (06:00–22:00)"
- [ ] Submit disabled until all required fields valid
- [ ] All validation errors shown inline in Bahasa Indonesia
- [ ] `HydrationCalculatorService.calculate()` runs on submit
- [ ] Confirmation screen: calculated target + modifier breakdown + disclaimer
- [ ] Manual adjustment: 1500–4000 ml range
- [ ] Store `targetDiterima: true/false`, `targetManualMl` if adjusted
- [ ] Generate `userId` UUID v4
- [ ] Save `UserProfile` to Isar
- [ ] **After profile confirmed:** `ReminderService.initialize()` called
- [ ] `SyncService.pushUnsyncedRecords()` — no-op stub in Phase 1

---

### F-04: Daily Dashboard

**Acceptance Criteria:**
- [ ] Circular progress ring showing `currentMl / targetMl`
- [ ] Center: `[currentMl]ml — [percent]%`
- [ ] Below ring: `[remainingMl]ml lagi`
- [ ] Quick-add: `+250ml`, `+500ml`, `Kustom`
- [ ] Kustom opens bottom sheet (min 50ml, max 2000ml)
- [ ] Today's log list: `HH:mm — Xml — [via app / via notifikasi]`
- [ ] Progress ring animates on new log
- [ ] Date shown at top: "Hari ini, 14 Mei"
- [ ] Target reached: ring turns green + celebration text + fun fact
- [ ] Notification permission denied banner if `notificationPermissionGranted: false`
- [ ] Random `kHydrationFacts` shown — refreshed each app open
- [ ] Streak badge: "🔥 X Hari Berturut-turut" (or "Mulai streak-mu!" if 0)
- [ ] Dashboard reads from `hydrationProvider` only — never directly from Isar
- [ ] Education entry point visible (bottom nav or FAB)

**Provider Init (READ-ONLY — Critical):**
- [ ] `HydrationNotifier` constructor calls `_loadToday()` immediately
- [ ] `_loadToday()` reads today's logs + profile from Isar — updates display state only
- [ ] `_loadToday()` does NOT perform midnight reset
- [ ] `_loadToday()` does NOT update `lastOpenedAt`
- [ ] `_loadToday()` does NOT increment `sessionCount`
- [ ] Loading spinner shown while `_loadToday()` runs
- [ ] Dashboard never shows 0% if logs exist for today

---

### F-05: Hydration Logging

**Acceptance Criteria:**
- [ ] +250ml, +500ml → immediate log, `loggedVia: 'app'`
- [ ] Custom: min 50ml, max 2000ml
- [ ] Save to Isar: `volume`, `timestamp`, `loggedVia`, `isSynced: false`
- [ ] After save: `hydrationProvider` updates immediately
- [ ] Upsert today's `DailySummary` (canonical pattern — AGENTS_V3.md §15)
  - Not exists: create with `achievedMl`, `complianceRate`, `firstLogTimestamp`
  - Exists: update `achievedMl`, `complianceRate` — preserve `sessionCount`, `firstLogTimestamp`
- [ ] Log appears in list: `HH:mm — Xml — via app`
- [ ] Undo available 5 seconds (SnackBar) — permanently deletes from Isar + recalculates DailySummary

---

### F-06: Reminder System

**Initialization:**
- [ ] `ReminderService.initialize()` called after profile confirmed
- [ ] Read `reminderWindowStart` and `reminderWindowEnd` from `UserProfile`
- [ ] Check current time against user's window
  - Within window → schedule first reminder 60 min from now
  - Outside window → schedule first reminder tomorrow at `reminderWindowStart:00`
- [ ] If `notificationPermissionGranted: false` → skip, set `reminderSystemActive: false`

**Dynamic Interval (3-Tier):**
- [ ] Recalculate after every log and every app open
- [ ] `progress < 40%` → remind every 60 minutes
- [ ] `40% ≤ progress ≤ 80%` → remind every 90 minutes
- [ ] `progress > 80%` → cancel all pending
- [ ] Target reached → cancel all + celebration

**Notification Content:**
- [ ] Title: `💧 Waktunya minum air!`
- [ ] Body: `Progress hari ini: X% — Yml lagi menuju target`
- [ ] Expanded: random `kHydrationFacts`

**Window Rules:**
- [ ] Never schedule outside user's `reminderWindowStart–reminderWindowEnd`
- [ ] Timezone: device local only
- [ ] At midnight reset: cancel all, reschedule for tomorrow at `reminderWindowStart`

**Boot Recovery:**
- [ ] `rescheduleIfNeeded()` called unconditionally on app open
- [ ] No pending + within window + progress < 80% → reschedule immediately

**ReminderResponse Creation:**
- [ ] When notification is **scheduled**: create `ReminderResponse` record with `actionUsed: null`, `notificationScheduledAt: DateTime.now()`
- [ ] This enables lazy `no_response` detection in startup sequence

**Android Requirements:**
- [ ] `AndroidScheduleMode.exactAllowWhileIdle`
- [ ] `SCHEDULE_EXACT_ALARM` permission
- [ ] Battery optimization whitelist dialog on first setup

---

### F-07: Direct Action Notification

**Acceptance Criteria:**
- [ ] Every reminder shows: `+250ml`, `+500ml`, `Buka App`
- [ ] Tap `+250ml` / `+500ml`: log to Isar with `loggedVia: 'notification_action'`
- [ ] Update existing `ReminderResponse`: set `completed: true`, `delayMinutes: 0`, `actionUsed: 'button_250'` or `'button_500'`
- [ ] After action: reschedule based on updated progress
- [ ] Dashboard reflects new total on next open

---

### F-08: Reminder Response Tracker

**Acceptance Criteria:**
- [ ] Notification tapped (opens app): update `ReminderResponse` → `completed: true`, `delayMinutes` = elapsed since `notificationScheduledAt`, `actionUsed: 'opened_app'`
- [ ] Action button used: `completed: true`, `delayMinutes: 0`
- [ ] Log within 30 min of notification (via app): `completed: true`, `delayMinutes` = elapsed
- [ ] No response (lazy detection at app open): `completed: false`, `delayMinutes: 60`, `actionUsed: 'no_response'`
- [ ] `remindersResponded` in DailySummary incremented only when `completed: true`
- [ ] `remindersSent` incremented when notification scheduled (not fired)

---

### F-09: Education Screen

**Article List (`/education`):**
- [ ] All `kHydrationArticles` as scrollable card list
- [ ] Each card: `emoji`, `title`, `summary`, category badge
- [ ] Filter by category: Semua / Mitos / Sains / Tips / Manfaat
- [ ] Tap → article detail screen
- [ ] Empty state if filter empty

**Article Detail:**
- [ ] Full `body` content
- [ ] Back button
- [ ] Title + category badge
- [ ] Read only — no share, no bookmark

**Content:** provided by researcher in `app_constants.dart` — agent must NOT generate

**Dashboard Integration:**
- [ ] Education accessible from bottom nav

---

### F-10: Settings Screen

**Acceptance Criteria:**

**Reminder Settings:**
- [ ] Display current reminder window (e.g., "07:00 – 21:00")
- [ ] Time picker to change `reminderWindowStart` and `reminderWindowEnd`
- [ ] Validate: start ≥ 06:00, end ≤ 22:00, gap ≥ 8 hours
- [ ] Error shown inline: "Jendela pengingat minimal 8 jam (antara 06:00–22:00)"
- [ ] On save: update `UserProfile` in Isar + call `ReminderService.rescheduleWithNewWindow()`
- [ ] `isSynced: false` on UserProfile after change

**Profile Summary (read-only):**
- [ ] Show: Jenis Kelamin, Berat Badan, Level Aktivitas, Letak Geografis
- [ ] Show: Target harian (ml)
- [ ] Edit Profile button → navigates to profile edit screen (re-uses F-03 form)

**App Info:**
- [ ] App version
- [ ] Research disclaimer: "Aplikasi ini digunakan sebagai instrumen penelitian"
- [ ] Reset data option (for testing only — guarded by confirmation dialog)

---

### F-11: History Screen (Riwayat)

**Goal:** Show hydration history for past days from Isar `DailySummary` records.

**Acceptance Criteria:**
- [ ] Accessible from bottom nav or dashboard
- [ ] List of past days showing: tanggal, `achievedMl / targetMl`, `complianceRate %`
- [ ] Color indicator per row: green (≥ 80%), yellow (50–79%), red (< 50%)
- [ ] Default: show last 7 days
- [ ] Tap on a day: expand to show that day's `HydrationLog` entries
- [ ] Empty state if no history exists yet
- [ ] Data source: Isar `DailySummary` + `HydrationLog` — never Supabase
- [ ] Today's data shown as "in progress" — not finalized
- [ ] Days where `dropoutFlag: true` shown with indicator

---

## PHASE 2 — SUPABASE INTEGRATION

> Do not begin until Phase 1 is complete and stable on real Android device for at least 3 days.

### F-12: Auto-Sync to Supabase

**Acceptance Criteria:**
- [ ] `SyncService.pushUnsyncedRecords()` enabled (remove no-op stub)
- [ ] Auth session fallback: check `currentSession`, call `signInAnonymously()` if null
- [ ] Push order: UserProfile → HydrationLog → ReminderResponse → DailySummary
- [ ] `users` + `daily_summaries`: `.upsert()` with `onConflict`
- [ ] `hydration_logs` + `reminder_responses`: `.insert()`
- [ ] Max 500 records per session — oldest first
- [ ] Records > 30 days: mark `isSynced: true` locally, skip push
- [ ] Each collection independent — partial failure does not block others
- [ ] Silent — no UI indication
- [ ] `nama` NEVER in any Supabase payload — verified by test

---

## PHASE 3 — NICE TO HAVE

### F-13: Gamification + Streak
- [ ] Uses `UserProfile.currentStreak` (already in schema)
- [ ] Streak increments in `performMidnightReset()` if compliance ≥ 80%
- [ ] Streak badge on dashboard
- [ ] Achievement badges: First Drop, 3 Day, 7 Day, Perfect Day, Early Bird

### F-14: Progress Screen
- [ ] Weekly bar chart (fl_chart)
- [ ] 80% compliance reference line
- [ ] Weekly compliance rate display

---

## Dropout Detection

> Implemented in F-00 splash startup. Not a separate feature.

- [ ] Compare `DateTime.now()` with `UserProfile.lastOpenedAt`
- [ ] Gap > 3 days: set `dropoutFlag: true` on BOTH `UserProfile` AND today's `DailySummary`
- [ ] If `dropoutNotificationSent == false`: schedule one re-engagement notification, then set `dropoutNotificationSent: true`
- [ ] Re-engagement notification requires F-06 to be complete first

---

## General UI Requirements

- Loading: `CircularProgressIndicator`
- Errors: `SnackBar` for user-facing failures (sync failures are silent)
- Empty states: every list must have a designed empty state
- No placeholder screens — every screen must be functional
- Hardware back button works correctly on Android
- All UI text in Bahasa Indonesia
- Fun facts displayed randomly — new fact each app open