# BUG POSSIBILITY — Interval, Jam Pengingat, Notifikasi, dan Riwayat SEHATI

Dokumen ini berisi daftar kemungkinan bug yang perlu dicek sebelum deploy aplikasi SEHATI. Fokus utama: interval pengingat, jam mulai-selesai, notifikasi, perubahan setting, data riwayat, dan efek samping ke dashboard/CSV.

> Keputusan produk saat ini:
> - Notifikasi hanya berfungsi sebagai pengingat.
> - Tap notifikasi membuka aplikasi.
> - Input minum dilakukan manual di dalam aplikasi.
> - Tidak ada input +250 ml / +500 ml dari notifikasi.
> - Reminder tetap aktif dan harus stabil.

---

## 1. Bug pada Interval Pengingat

### 1.1 Interval tidak tersimpan
**Kemungkinan bug:** user memilih interval 2 jam, tetapi setelah app ditutup/dibuka kembali interval kembali ke default.

**Dampak:** pengingat tidak sesuai pilihan user.

**Yang harus dicek:**
- Setting interval tersimpan di local storage / profile.
- Dashboard/settings menampilkan interval terbaru.
- Setelah restart app, interval tetap sama.

**Expected behavior:** interval yang dipilih user harus persist.

### 1.2 Interval berubah tapi jadwal lama tidak dibatalkan
**Kemungkinan bug:** user mengubah interval dari 1 jam ke 3 jam, tetapi notifikasi lama dari interval 1 jam masih aktif.

**Dampak:** notifikasi dobel atau terlalu sering.

**Yang harus dicek:**
- Saat interval berubah, semua reminder lama dibatalkan terlebih dahulu.
- Jadwal baru dibuat berdasarkan interval terbaru.
- Tidak ada duplicate notification.

**Expected behavior:** change interval = cancel old schedule → create new schedule.

### 1.3 Interval menghasilkan jadwal di luar window
**Kemungkinan bug:** window 07.00–21.00, interval 3 jam, tetapi notifikasi muncul pukul 22.00 atau lebih.

**Dampak:** user terganggu dan logic reminder dianggap rusak.

**Expected behavior:** tidak ada reminder di luar jam mulai-selesai.

### 1.4 Interval terlalu pendek untuk production
**Kemungkinan bug:** interval debug/testing seperti 5 menit ikut muncul di release build.

**Dampak:** user menerima notifikasi terlalu sering, aplikasi terasa spam.

**Expected behavior:** interval production hanya 1 jam / 2 jam / 3 jam. Interval testing hanya muncul di debug mode jika memang ada.

### 1.5 Interval 0/null menyebabkan crash
**Kemungkinan bug:** data interval null, 0, atau invalid dari storage lama menyebabkan error scheduling.

**Expected behavior:** jika interval invalid, gunakan default aman, misalnya 2 jam.

---

## 2. Bug pada Jam Mulai dan Jam Selesai

### 2.1 Jam mulai lebih besar dari jam selesai
**Kemungkinan bug:** user memilih start 21.00 dan end 07.00.

**Dampak:** logic bingung apakah window lintas hari atau invalid.

**Expected behavior:** jika overnight window tidak didukung, tampilkan validasi: “Waktu mulai harus lebih awal dari waktu selesai.”

### 2.2 Durasi window kurang dari minimum
**Kemungkinan bug:** user memilih 10.00–12.00 padahal minimum window 8 jam.

**Expected behavior:** jika kurang dari 8 jam, tampilkan error dan jangan simpan.

### 2.3 Jam mulai/sesai berubah tapi jadwal lama tidak ikut update
**Kemungkinan bug:** user mengubah window dari 07.00–21.00 ke 09.00–18.00, tapi notifikasi tetap muncul jam 07.00.

**Expected behavior:** saat window berubah, cancel old schedule lalu re-schedule berdasarkan window baru.

### 2.4 User mengubah window pada hari yang sama
**Contoh kasus:** sekarang pukul 15.00, window lama 07.00–21.00, user ubah ke 08.00–14.00. App masih menjadwalkan reminder sore padahal window baru sudah lewat.

**Expected behavior:** jika waktu sekarang sudah di luar window baru, jangan jadwalkan reminder lagi hari itu. Jadwalkan ulang mulai hari berikutnya.

### 2.5 User membuka app di luar window
**Kemungkinan bug:** app mencatat response atau menjadwalkan reminder baru saat user membuka app pukul 23.00.

**Expected behavior:** di luar window, app tidak perlu menjadwalkan reminder untuk hari itu. App tetap boleh menampilkan dashboard dan logging manual.

---

## 3. Bug pada Scheduling Notifikasi

### 3.1 Reminder tidak muncul
**Kemungkinan penyebab:** permission belum aktif, channel Android belum dibuat, exact alarm diblokir, battery optimization, atau scheduling gagal tanpa feedback.

**Expected behavior:** jika izin belum aktif, tampilkan status dan arahan. Debug test notification harus membantu isolasi masalah.

### 3.2 Reminder muncul dobel
**Kemungkinan bug:** setiap buka app atau ubah setting membuat jadwal baru tanpa membatalkan jadwal lama.

**Expected behavior:** untuk satu slot waktu, hanya ada satu notifikasi.

### 3.3 Reminder tetap muncul setelah dimatikan
**Kemungkinan bug:** user toggle reminder off, tapi jadwal lama tidak dibatalkan.

**Expected behavior:** toggle off = cancel semua reminder aktif.

### 3.4 Reminder tidak muncul setelah diaktifkan ulang
**Kemungkinan bug:** toggle on tidak memanggil scheduling ulang.

**Expected behavior:** toggle on = validasi permission + schedule reminder berdasarkan setting terbaru.

### 3.5 Notifikasi muncul di hari yang salah
**Kemungkinan bug:** date calculation salah, terutama saat lewat tengah malam.

**Expected behavior:** reminder mengikuti tanggal dan timezone lokal device.

### 3.6 Test notification masuk ke data penelitian
**Kemungkinan bug:** debug test notification dianggap reminder sungguhan.

**Expected behavior:** test notification tidak menambah ReminderResponse, DailySummary, remindersSent, CSV, atau statistik apa pun.

---

## 4. Bug pada Permission Notifikasi

### 4.1 User menolak permission
**Kemungkinan bug:** app tetap menganggap reminder aktif walaupun izin ditolak.

**Expected behavior:** tampilkan status “Notifikasi belum aktif” dan jangan tampilkan seolah reminder aktif penuh.

### 4.2 User mematikan permission dari sistem
**Kemungkinan bug:** app tidak sadar permission sudah dimatikan lewat Android Settings.

**Expected behavior:** saat app dibuka, cek ulang permission dan sinkronkan UI settings.

### 4.3 Permission permanently denied
**Kemungkinan bug:** app terus meminta permission padahal sudah ditolak permanen.

**Expected behavior:** arahkan user ke system settings, jangan request permission berulang tanpa hasil.

---

## 5. Bug pada Tap Notifikasi

### 5.1 Tap notifikasi tidak membuka app
**Kemungkinan bug:** payload/callback tidak terhubung dengan benar.

**Expected behavior:** tap body notifikasi membuka aplikasi.

### 5.2 Tap notifikasi menambah HydrationLog
**Kemungkinan bug:** logic lama action notification masih aktif.

**Expected behavior:** tap notifikasi hanya membuka app. Tidak ada log minum otomatis dan daily total tidak berubah.

### 5.3 Tap notifikasi test dihitung sebagai opened_app real
**Kemungkinan bug:** debug test notification masuk ke ReminderResponse.

**Expected behavior:** test notification diabaikan oleh response tracking.

### 5.4 opened_app response delay negatif
**Kemungkinan bug:** lastReminderSentAt disimpan sebagai waktu schedule, bukan fire time. Jika app dibuka sebelum notifikasi benar-benar muncul, delay bisa negatif.

**Expected behavior:** delayMinutes harus di-clamp minimal 0.

---

## 6. Bug pada No Response Tracking

### 6.1 No response tidak tercatat
**Kemungkinan bug:** user tidak merespons reminder, tetapi sistem tidak pernah menandai no_response.

**Expected behavior:** saat app dibuka berikutnya, pending reminder lama bisa ditandai no_response jika melewati threshold.

### 6.2 No response tercatat terlalu cepat
**Kemungkinan bug:** threshold salah atau waktu reminder salah.

**Expected behavior:** no_response hanya tercatat setelah melewati batas waktu yang valid.

### 6.3 Duplicate no_response
**Kemungkinan bug:** satu reminder pending ditandai no_response berkali-kali.

**Expected behavior:** satu reminder hanya boleh punya satu final response.

---

## 7. Bug pada Daily Summary dan Riwayat

### 7.1 Total minum salah setelah logging manual
**Kemungkinan bug:** HydrationLog tersimpan, tapi DailySummary tidak update.

**Expected behavior:** tambah minum manual → total dashboard dan history langsung update.

### 7.2 Riwayat tanggal salah
**Kemungkinan bug:** log masuk ke tanggal UTC, bukan tanggal lokal.

**Expected behavior:** log masuk ke tanggal lokal user.

### 7.3 First/last drink time salah
**Kemungkinan bug:** setelah delete/edit log, firstLogTimestamp atau lastLogTimestamp tidak dihitung ulang.

**Expected behavior:** jika semua log hari itu dihapus, first/last time harus kosong. Jika log diedit/dihapus, summary recalculated.

### 7.4 Progress lebih dari 100% merusak UI
**Kemungkinan bug:** user minum di atas target, progress ring/bar overflow.

**Expected behavior:** raw percentage boleh >100%, visual progress harus clamp ke 100%, status “Target tercapai”.

### 7.5 Weekly summary salah
**Kemungkinan bug:** 7 hari terakhir mengambil tanggal tidak tepat atau mencampur hari.

**Expected behavior:** weekly summary menghitung 7 hari lokal terakhir.

---

## 8. Bug pada Perubahan Target Harian

### 8.1 User mengubah target setelah sudah logging
**Kemungkinan bug:** progress hari itu tidak recalculated.

**Expected behavior:** total ml tetap sama, persentase target recalculated berdasarkan target baru, dashboard/history sinkron.

### 8.2 Target invalid
**Kemungkinan bug:** target 0, negatif, null, atau terlalu kecil/besar bisa disimpan.

**Expected behavior:** validasi target dengan rentang aman sesuai keputusan produk.

---

## 9. Bug pada Reset Data

### 9.1 Reset data tidak membatalkan reminder
**Kemungkinan bug:** user reset data, tapi reminder lama tetap aktif.

**Expected behavior:** reset data harus clear profile/log/summary/settings terkait dan cancel reminder.

### 9.2 Reset data menyisakan SharedPreferences lama
**Kemungkinan bug:** pending keys atau migration flags tersisa.

**Expected behavior:** reset full harus bersih. Karena app belum punya user, reset agresif boleh dilakukan saat testing.

---

## 10. Bug pada CSV Export

### 10.1 CSV menampilkan field teknis
**Kemungkinan bug:** CSV berisi id, loggedVia, responseLogId, dropoutFlag, notificationAction, dan field teknis lain.

**Expected behavior:** CSV hanya berisi data harian sederhana.

Kolom rekomendasi:
- tanggal
- target_harian_ml
- total_minum_ml
- persentase_target
- status_target
- jumlah_catatan_minum
- waktu_minum_pertama
- waktu_minum_terakhir

### 10.2 CSV total tidak sama dengan UI
**Kemungkinan bug:** export menghitung ulang dari sumber berbeda dan hasilnya beda dari dashboard/history.

**Expected behavior:** angka CSV harus sama dengan history harian.

### 10.3 CSV gagal saat data kosong
**Kemungkinan bug:** export crash jika belum ada log.

**Expected behavior:** export data kosong harus ditangani dengan pesan jelas atau file kosong yang valid.

---

## 11. Bug pada Lifecycle App

### 11.1 App killed lalu reminder tidak muncul
**Kemungkinan bug:** scheduled notification tidak bertahan setelah app killed.

**Expected behavior:** reminder terjadwal tetap muncul walau app ditutup.

### 11.2 Device reboot
**Kemungkinan bug:** schedule hilang setelah HP restart.

**Expected behavior:** jika reboot handling belum ada, dokumentasikan sebagai risiko. Minimal app melakukan reschedule saat dibuka kembali.

### 11.3 Battery optimization
**Kemungkinan bug:** beberapa device membatasi notification scheduling.

**Expected behavior:** app tidak crash dan QA mencatat device-specific risk.

---

## 12. Bug pada UI Settings Reminder

### 12.1 UI menampilkan status yang tidak sesuai logic
**Kemungkinan bug:** toggle aktif, tapi permission mati.

**Expected behavior:** UI harus memberi status jelas. Jangan tampilkan seolah semua aktif jika permission mati.

### 12.2 Error validation tidak jelas
**Kemungkinan bug:** user memilih jam invalid tapi tidak tahu kenapa tidak bisa disimpan.

**Expected behavior:** error message jelas dan pendek.

Contoh:
- “Waktu mulai harus lebih awal dari waktu selesai.”
- “Rentang pengingat minimal 8 jam.”
- “Aktifkan izin notifikasi agar pengingat bisa muncul.”

---

## 13. Prioritas Fix Sebelum Deploy

### Critical
- Reminder tidak muncul.
- Reminder dobel.
- Reminder tetap muncul setelah dimatikan.
- Tap notifikasi menambah HydrationLog.
- Action button +250/+500 masih muncul.
- App crash saat scheduling.
- Manual logging tidak update dashboard/history.

### High
- Window start/end invalid bisa disimpan.
- Interval berubah tapi jadwal lama tidak dibatalkan.
- Permission mati tapi UI bilang aktif.
- CSV total tidak sama dengan UI.
- Visual progress overflow di atas 100%.

### Medium
- opened_app delay negatif.
- no_response duplicate.
- first/last drink time tidak recalculated.
- Weekly summary salah.
- Test notification masuk data real.

### Low
- Copy notifikasi kurang konsisten.
- UI error message kurang rapi.
- Device reboot belum auto-reschedule.
- Battery optimization device-specific.

---

## 14. Manual QA Checklist Real Device

1. Fresh install app.
2. Selesaikan onboarding dan profile setup.
3. Aktifkan permission notifikasi.
4. Set reminder ON.
5. Set window valid.
6. Set interval 1 jam / 2 jam / 3 jam.
7. Trigger debug test notification.
8. Pastikan notifikasi muncul tanpa action buttons.
9. Tap notifikasi.
10. Pastikan app terbuka.
11. Pastikan total minum tidak berubah.
12. Tambah minum manual.
13. Pastikan dashboard update.
14. Pastikan history update.
15. Ubah interval.
16. Pastikan jadwal lama tidak dobel.
17. Ubah jam mulai-selesai.
18. Pastikan window invalid ditolak.
19. Matikan reminder.
20. Pastikan reminder lama dibatalkan.
21. Export CSV.
22. Pastikan kolom CSV sederhana dan angka cocok dengan UI.
23. Restart app.
24. Pastikan profile, setting, log, dan history persist.

---

## 15. Prompt untuk AI Agent: Audit dan Perbaikan

```text
Read the current project files first before editing.

Task:
Perform a focused QA audit and bug-fix pass for SEHATI reminder interval, start/end time window, notification behavior, permission handling, notification tap behavior, daily summary/history, and CSV export consistency.

Context:
SEHATI is close to deployment.
The app has no production users yet.
Notification drink input has been removed from product scope.
Reminder notifications should only remind the user and open the app when tapped.
Users log water manually inside the app.

Do not add new features.
Do not redesign UI.
Do not re-add +250 ml / +500 ml notification action buttons.
Do not create HydrationLog from notification response.
Do not modify daily water intake total from notification response.

Product rules:
1. Production interval options must remain realistic, such as 1 hour, 2 hours, and 3 hours.
2. Do not expose 5-minute interval in release.
3. Reminder window must be valid.
4. If overnight window is not supported, start time must be earlier than end time.
5. Minimum reminder window duration must be enforced if configured, such as 8 hours.
6. Reminder notifications must not appear outside the selected window.
7. Changing interval or window must cancel old schedules and create new schedules.
8. Turning reminder off must cancel scheduled reminders.
9. Turning reminder on must schedule reminders based on current settings.
10. Notification permission state must be handled clearly.
11. Tap notification body should open the app.
12. Tap notification must not log water.
13. Debug test notifications must not enter research/response/summary/export data.
14. ReminderResponse opened_app/no_response tracking may remain.
15. Visual progress indicators must clamp to 100%, but raw percentage may exceed 100%.
16. CSV must remain simple and daily aggregated.

Audit these areas:
- reminder_service.dart
- reminder_logic.dart
- reminder_provider.dart
- settings_screen.dart
- splash_screen.dart
- main.dart
- hydration_provider.dart
- logging_repository.dart
- export_service.dart
- daily_summary_model.dart
- hydration_log_model.dart
- any notification/debug test code

Specific checks and fixes:

1. Interval validation and persistence
- Ensure interval values are valid and persisted.
- Ensure invalid/null/zero interval falls back safely.
- Ensure changing interval cancels old schedule before scheduling new notifications.
- Ensure no duplicate reminders are created.

2. Start/end reminder window
- Ensure start/end time validation is correct.
- Ensure invalid windows cannot be saved.
- Ensure minimum duration rule is enforced.
- Ensure scheduling only occurs inside the window.
- Ensure changing window reschedules future notifications safely.

3. Notification scheduling
- Ensure reminders appear only inside allowed window.
- Ensure reminder off cancels scheduled reminders.
- Ensure reminder on schedules correctly.
- Ensure no duplicate notifications.
- Ensure scheduling errors do not crash the app.

4. Notification permission
- Ensure denied permission is handled.
- Ensure permanently denied permission guides user to settings.
- Ensure UI does not show reminder as fully active if permission is disabled.

5. Notification tap behavior
- Ensure notification has no +250 ml / +500 ml action buttons.
- Ensure no explicit Buka App action button remains unless system default tap behavior.
- Ensure tapping notification opens app.
- Ensure tapping notification does not create HydrationLog.
- Ensure daily total does not change from notification tap.
- Ensure debug test notifications are ignored by response tracking.

6. ReminderResponse/no_response
- Ensure opened_app response does not get negative delayMinutes. Clamp to 0 if needed.
- Ensure no_response is not duplicated.
- Ensure test notifications do not create ReminderResponse.

7. DailySummary and History
- Ensure manual logging updates dashboard and history.
- Ensure total intake is correct.
- Ensure first/last drink time recalculates correctly after add/edit/delete.
- Ensure empty day state is correct.
- Ensure weekly summary uses correct local dates.
- Ensure visual progress clamps to 100%.

8. CSV Export
- Ensure CSV does not include technical fields.
- Ensure CSV totals match history UI.
- Ensure CSV handles empty data safely.
- Final CSV columns should be:
  - tanggal
  - target_harian_ml
  - total_minum_ml
  - persentase_target
  - status_target
  - jumlah_catatan_minum
  - waktu_minum_pertama
  - waktu_minum_terakhir

9. Search for forbidden/old notification action references
Ensure no invalid references remain:
- kActionId250
- kActionId500
- kActionIdOpenApp
- kPendingActionsKey
- NotificationActionLog
- notification_action_log
- queueActionLog
- flushActionQueue
- _flushNotificationActions

If any remain, explain why or remove safely.

Testing:
Run:
- flutter analyze
- flutter test if tests exist

Manual QA guidance:
Provide a checklist for real Android device testing:
- fresh install
- onboarding/profile
- permission grant/deny
- reminder on/off
- interval changes
- start/end time changes
- debug test notification
- tap notification
- manual logging
- history
- CSV export
- restart app

Final report must include:
1. Files inspected.
2. Bugs found.
3. Bugs fixed.
4. Files changed.
5. Items intentionally left unchanged and why.
6. flutter analyze result.
7. Remaining risks before deployment.
8. Manual QA checklist.
```

---

## 16. Deployment Gate

Jangan deploy sebelum ini aman:

- `flutter analyze` bersih.
- Notifikasi muncul di real device.
- Tidak ada action button +250/+500.
- Tap notifikasi tidak menambah air.
- Reminder off benar-benar cancel.
- Interval/window tidak membuat duplicate reminder.
- Manual logging update dashboard/history.
- CSV angka cocok dengan UI.
- App tidak crash setelah restart.
