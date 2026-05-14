# FEATURES.md
# Feature Specifications & Acceptance Criteria
# Personal Hydration Tracker

> This file defines what "done" means for each feature.
> Agent must satisfy ALL acceptance criteria before moving to next feature.
> Do not mark a feature complete if any criterion is unmet.

---

## Build Order

### Phase 1 — Research Core (complete and stabilize before Phase 2)
```
1.  Project Setup & Theme          (F-01)
2.  Splash & Navigation Guard      (F-00)
3.  Onboarding                     (F-02)
4.  Profile Setup + Calculator     (F-03)
5.  Daily Dashboard shell          (F-04)
6.  Hydration Logging              (F-05)
7.  Reminder System                (F-06)
8.  Direct Action Notification     (F-07)
9.  Reminder Response Tracker      (F-08)
10. Education Screen               (F-09)
11. Auto-sync to Supabase          (F-10)
```

### Phase 2 — Nice to Have (only if Phase 1 complete and stable)
```
12. Gamification + Streak          (F-11)
13. Progress Screen                (F-12)
```

---

## PHASE 1 — RESEARCH CORE

---

### F-01: Project Setup & Theme

**Acceptance Criteria:**
- [ ] `flutter create` with package name `com.research.hydration_tracker`
- [ ] All packages in AGENTS.md installed in `pubspec.yaml`
- [ ] `AppTheme`, `AppColors`, `AppTypography` defined in `app/theme/`
- [ ] Primary color: deep blue `#1A73E8`, background: white, accent: `#E8F0FE`
- [ ] `go_router` configured, all routes stubbed with empty `Scaffold`
- [ ] `main.dart` wraps app in `ProviderScope`
- [ ] `kHydrationFacts` (15 facts) and `kHydrationArticles` (10–15 articles) hardcoded in `core/constants/app_constants.dart`
- [ ] App runs on Android without errors

---

### F-00: Splash Screen & Navigation Guard

> Built as part of F-01 but listed separately — entry point for all routing logic.

**Acceptance Criteria:**
- [ ] Splash screen is the first route (`/`) — shows app logo for ~1.5 seconds
- [ ] On splash: read `isOnboarded` from `shared_preferences`
  - `false` → navigate to `/onboarding`
  - `true` → query Isar for `UserProfile`
    - Profile exists → navigate to `/dashboard`
    - Profile missing → navigate to `/profile-setup`
- [ ] Routing logic runs every time app is opened — including after cleared from recent apps
- [ ] On every app open: check `lastOpenedAt` vs today — if different, trigger `performMidnightReset()` before navigating
- [ ] After midnight check: call `SyncService.pushUnsyncedRecords()` (fire and forget)
- [ ] After sync call: call `ReminderService.rescheduleIfNeeded()`
- [ ] Update `UserProfile.lastOpenedAt` to `DateTime.now()` on every open
- [ ] No manual `Navigator.push()` — use `go_router` redirect logic

---

### F-02: Onboarding

**Acceptance Criteria:**
- [ ] 3-page onboarding using `smooth_page_indicator`
- [ ] Page 1: App intro + research purpose explanation + one random `kHydrationFacts` item displayed
- [ ] Page 2: How the app works — visual flow of: profile → target → reminder → log → education
- [ ] Page 3: Notification permission request via `permission_handler`
- [ ] Permission result stored in Isar `UserProfile.notificationPermissionGranted: bool`
- [ ] If permission denied: allow skip, show persistent banner on dashboard
- [ ] On complete: write `isOnboarded: true` to `shared_preferences`
- [ ] On relaunch: if `isOnboarded == true`, skip onboarding entirely
- [ ] "Skip" option available from page 1
- [ ] If user skips onboarding: `notificationPermissionGranted` defaults to `false` in UserProfile

---

### F-03: User Profile Setup + Hydration Calculator

**Acceptance Criteria:**
- [ ] Form fields: Gender (dropdown: male/female), Age (int), Weight in kg (decimal), Activity Level (dropdown: sedentary/light/moderate/active/very_active)
- [ ] All fields required — cannot submit if empty
- [ ] Age validation: 10–80 years
- [ ] Weight validation: 20–200 kg
- [ ] On submit: `HydrationCalculatorService.calculate()` runs, result clamped to 1500–4000ml
- [ ] Confirmation screen shows: calculated target + formula explanation
- [ ] User can adjust target manually within 1500–4000ml range
- [ ] If accepted as-is: store `targetAccepted: true`
- [ ] If manually adjusted: store `targetAccepted: false`, `manualTargetMl: X`
- [ ] Generate `userId` as UUID v4, store in `UserProfile.userId`
- [ ] Call `signInAnonymously()` on Supabase immediately after `userId` is generated, before saving to Isar
- [ ] Profile saved to Isar `UserProfile` collection
- [ ] **Immediately after profile confirmed:**
  - `ReminderService.initialize()` called
  - `SyncService.pushUnsyncedRecords()` called (pushes new profile to Supabase)
- [ ] Profile screen accessible from settings for editing (non-blocking for MVP)

---

### F-04: Daily Dashboard

**Acceptance Criteria:**
- [ ] Circular progress ring (`percent_indicator`) showing `currentMl / targetMl`
- [ ] Center of ring: current ml + percentage (e.g., "1200ml — 48%")
- [ ] Below ring: remaining ml (e.g., "1300ml lagi")
- [ ] Quick-add buttons: `+250ml`, `+500ml`, `Custom`
- [ ] Custom opens bottom sheet with numeric input (min 50ml, max 2000ml)
- [ ] Today's log list: scrollable, each entry shows `HH:mm — Xml — [source]`
  - source: `via app` or `via notifikasi`
- [ ] Progress ring animates on new log
- [ ] Date shown at top (e.g., "Hari ini, 14 Mei")
- [ ] If target reached: ring turns green, celebration text + random fun fact shown
- [ ] Notification permission denied banner shown if `notificationPermissionGranted: false`
- [ ] Random `kHydrationFacts` item shown — refreshed on each app open
- [ ] Dashboard reads from `hydrationProvider` only — never directly from Isar

**Provider Init (Critical):**
- [ ] `HydrationNotifier` constructor immediately calls `_loadToday()` on creation
- [ ] `_loadToday()` reads today's logs from Isar and updates state before UI renders
- [ ] Dashboard never shows 0% progress if logs exist in Isar for today
- [ ] If app cleared from recent apps and reopened: dashboard shows correct accumulated intake
- [ ] Loading state shown while `_loadToday()` is running (spinner inside progress ring)

---

### F-05: Hydration Logging

**Acceptance Criteria:**
- [ ] Quick-add 250ml and 500ml trigger immediate log with `loggedVia: 'app'`
- [ ] Custom input: min 50ml, max 2000ml
- [ ] Each log saved to Isar: `volume`, `timestamp` (device time), `loggedVia`, `isSynced: false`
- [ ] After save: `hydrationProvider` updates, dashboard reflects new total immediately
- [ ] After save: upsert today's `DailySummary` in Isar following canonical upsert pattern in AGENTS.md Section 15
- [ ] If DailySummary for today does not exist: create new record with `achievedMl`, `complianceRate`, `firstLogTimestamp` (if first log today)
- [ ] If DailySummary for today exists: update `achievedMl` and `complianceRate`, preserve `sessionCount` and `firstLogTimestamp`
- [ ] Each log shows in today's list: `HH:mm — Xml — via app`
- [ ] Undo available 5 seconds after log (Snackbar with undo)
- [ ] Undo permanently deletes entry from Isar and recalculates DailySummary

---

### F-06: Reminder System

**Goal:** Dynamic local notifications initialized from profile setup.

**Acceptance Criteria:**

**Initialization:**
- [ ] `ReminderService.initialize()` called immediately after profile confirmed in F-03
- [ ] Check current time against reminder window (07:00–21:00)
  - Within window → schedule first reminder 60 minutes from now
  - Outside window → schedule first reminder tomorrow at 07:00
- [ ] If `notificationPermissionGranted: false` → skip scheduling, set `reminderSystemActive: false`

**Dynamic Interval (3-Tier):**
- [ ] Recalculate and reschedule after every hydration log and every app open
- [ ] `progress < 40%` → remind every 60 minutes
- [ ] `40% ≤ progress ≤ 80%` → remind every 90 minutes
- [ ] `progress > 80%` → cancel all pending notifications
- [ ] Target reached → cancel all + show celebration on dashboard

**Notification Content:**
- [ ] Title: `💧 Waktunya minum air!`
- [ ] Body: `Progress hari ini: X% — Yml lagi menuju target`
- [ ] Random `kHydrationFacts` item shown as expanded notification text

**Window Rules:**
- [ ] No notification sent outside 07:00–21:00
- [ ] Timezone: device local only — no timezone switching support

**Boot Recovery:**
- [ ] `ReminderService.rescheduleIfNeeded()` called on every app open unconditionally
- [ ] Checks pending notification count
  - Pending exists → skip
  - No pending + within window + progress < 80% → reschedule immediately
- [ ] Handles Xiaomi/OPPO/Vivo/Realme aggressive process killing

**Android Requirements:**
- [ ] `AndroidScheduleMode.exactAllowWhileIdle`
- [ ] `SCHEDULE_EXACT_ALARM` permission requested
- [ ] Battery optimization whitelist dialog shown once on first setup

---

### F-07: Direct Action Notification

**Goal:** User can log water directly from notification without opening app.

**Acceptance Criteria:**
- [ ] Every reminder notification shows two action buttons: `+250ml` and `+500ml`
- [ ] Tapping action button: logs to Isar with `loggedVia: 'notification_action'`
- [ ] Logs `ReminderResponse`: `completed: true`, `delayMinutes: 0`, `actionUsed: 'button_250'` or `'button_500'`
- [ ] After action: reschedule notifications based on updated progress
- [ ] Dashboard reflects new total on next open
- [ ] "Buka App" button opens app to dashboard

---

### F-08: Reminder Response Tracker

**Goal:** Capture user behavior after every notification for research analysis.

**Acceptance Criteria:**
- [ ] Notification tapped (opens app): `completed: true`, `delayMinutes` = time since notification sent, `actionUsed: 'opened_app'`
- [ ] Notification action button used: `completed: true`, `delayMinutes: 0`, `actionUsed: 'button_250'` or `'button_500'`
- [ ] User logs water within 30 min of notification (via app): `completed: true`, `delayMinutes` = actual elapsed
- [ ] No response within 60 minutes: `completed: false`, `delayMinutes: 60`, `actionUsed: 'no_response'`
- [ ] All `ReminderResponse` records saved to Isar with `isSynced: false`
- [ ] `remindersSent` in today's DailySummary incremented when notification is **scheduled** (not when fired)
- [ ] `remindersResponded` in today's DailySummary incremented when `ReminderResponse` is recorded with `completed: true`

---

### F-09: Education Screen

**Goal:** Provide hardcoded hydration education content — no network, no CMS, no admin needed.

**Acceptance Criteria:**

**Article List Screen (`/education`):**
- [ ] Displays all `kHydrationArticles` as scrollable card list
- [ ] Each card shows: `emoji`, `title`, `summary`, `category` badge
- [ ] Cards filterable by category: All / Mitos / Sains / Tips / Manfaat
- [ ] Tapping card navigates to article detail screen
- [ ] Empty state shown if filter returns no results (should not happen with hardcoded data)

**Article Detail Screen:**
- [ ] Shows full `body` content of selected article
- [ ] Back button returns to list
- [ ] Title and category badge shown at top
- [ ] No share button, no bookmark — read only

**Content Requirements (to be filled by researcher — agent must NOT generate this content):**
- [ ] Minimum 10 articles, maximum 15
- [ ] At least 2 articles per category
- [ ] All content in Indonesian language
- [ ] Content provided in `app_constants.dart` by researcher before F-09 is implemented
- [ ] Topics must include:
  - Debunking "8 gelas sehari" myth
  - Dehidrasi ringan dan efeknya pada konsentrasi
  - Waktu terbaik untuk minum air
  - Air putih vs minuman lain
  - Tanda-tanda dehidrasi
  - Manfaat hidrasi untuk kulit dan ginjal
  - Hubungan air dan performa fisik
  - Tips minum air yang konsisten

**Dashboard Integration:**
- [ ] Education icon/button visible on dashboard (bottom nav or FAB area)
- [ ] Does not interfere with primary logging flow

---

### F-10: Auto-Sync to Supabase

**Goal:** Research data reaches Supabase automatically — no user action required.

**Acceptance Criteria:**
- [ ] `SyncService.pushUnsyncedRecords()` called on every app open (triggered from F-00 splash logic)
- [ ] Reads all Isar records where `isSynced: false` across: UserProfile, HydrationLog, ReminderResponse, DailySummary
- [ ] **Maximum 500 records per sync session** — if more exist, push oldest 500 first, rest on next open
- [ ] **Records older than 30 days**: mark `isSynced: true` locally, do not push to Supabase
- [ ] Pushes in order: user profile → hydration_logs → reminder_responses → daily_summaries
- [ ] Each collection syncs independently — failure in one does not block others
- [ ] On success per record: mark `isSynced: true` in Isar
- [ ] On failure: silent — log to console only, retry on next app open
- [ ] User sees no UI indication of sync — completely transparent
- [ ] Never blocks app startup or UI rendering — runs async after navigation completes
- [ ] Handles duplicate prevention via Supabase UNIQUE constraints (upsert strategy)

---

## PHASE 2 — NICE TO HAVE

> Do not implement until all Phase 1 features are complete, tested on a real Android device, and stable for at least 3 days of continuous use.

---

### F-11: Gamification + Streak

> ⚠️ Research value: NONE. Implements only for user retention during study period.

**Acceptance Criteria:**
- [ ] Streak counter stored in `UserProfile.currentStreak`
- [ ] Streak increments during `performMidnightReset()` if compliance ≥ 80%
- [ ] Streak resets to 0 if compliance < 80%; record `streakBreakHour`
- [ ] Streak shown on dashboard: "🔥 X Hari Berturut-turut"
- [ ] Achievements screen: earned badges (with date) + locked badges (greyed out)
- [ ] Badges: First Drop, 3 Day Streak, 7 Day Streak, Perfect Day, Early Bird
- [ ] Badge earned → one-time celebration dialog (not repeated on reopen)
- [ ] `checkAchievements()` is idempotent — never awards duplicates

---

### F-12: Progress Screen

> ⚠️ For user motivation only. Researcher uses Supabase data directly for analysis.

**Acceptance Criteria:**
- [ ] Weekly chart: bar chart (fl_chart) of daily compliance for last 7 days
- [ ] Horizontal reference line at 80% compliance target
- [ ] Weekly compliance rate displayed (e.g., "Minggu ini: 71% patuh")
- [ ] Tapping bar shows tooltip with exact ml and compliance %
- [ ] Empty state shown if no data for period

---

## Dropout Detection (Research Variable — Phase 1)

> Implemented inside F-00 splash logic, not as a separate feature.

- [ ] On every app open: compare `DateTime.now()` with `UserProfile.lastOpenedAt`
- [ ] If gap > 3 days: set `dropoutFlag: true` in UserProfile AND today's DailySummary
- [ ] Send one re-engagement notification (check `dropoutNotificationSent` flag — one-time only)
- [ ] `dropoutFlag` synced to Supabase via auto-sync

---

## General UI Requirements (All Features)

- Loading states: `CircularProgressIndicator` during async operations
- Error states: `SnackBar` for user-facing failures (not sync failures — those are silent)
- Empty states: every list must have a designed empty state
- No placeholder screens — every implemented screen must be functional
- Hardware back button must work correctly on Android
- Fun facts (`kHydrationFacts`) displayed randomly — new fact on each dashboard open