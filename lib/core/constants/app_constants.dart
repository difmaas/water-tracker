/// Application-wide constants for Sehati.
library;

// ── Route Names ──────────────────────────────────────────────────────────────

const String kRouteSplash = '/';
const String kRouteOnboarding = '/onboarding';
const String kRouteProfileSetup = '/profile-setup';
const String kRouteDashboard = '/dashboard';
const String kRouteEducation = '/education';
const String kRouteProgress = '/progress';
const String kRouteAchievements = '/achievements';
const String kRouteSettings = '/settings';

// ── App Info & Research ───────────────────────────────────────────────────────

const String kSettingsResearchDisclaimer =
    'Aplikasi ini digunakan sebagai instrumen penelitian OPSI. '
    'Seluruh data yang dikumpulkan bersifat anonim dan hanya digunakan untuk kepentingan riset.';


// ── Hydration Defaults ───────────────────────────────────────────────────────

/// Minimum daily target in ml (clamp lower bound).
const int kTargetClampMin = 1500;

/// Maximum daily target in ml (clamp upper bound).
const int kTargetClampMax = 4000;

/// Reminder active window start hour (inclusive).
const int kReminderWindowStart = 7; // 07:00

/// Reminder active window end hour (inclusive).
const int kReminderWindowEnd = 21; // 21:00

// ── Notification Action IDs (F-07) ───────────────────────────────────────────

/// Action button ID for the +250ml quick-log button on reminder notifications.
const String kActionId250 = 'action_250';

/// Action button ID for the +500ml quick-log button on reminder notifications.
const String kActionId500 = 'action_500';

/// Action button ID for the "Buka App" button on reminder notifications.
const String kActionIdOpenApp = 'action_open';

/// SharedPreferences key for the pending notification action queue.
/// Background isolate writes here; Splash screen flushes on next open.
const String kPendingActionsKey = 'pending_notification_actions';

// ── Reminder Response Tracking Keys (F-08) ───────────────────────────────────

/// SharedPreferences key storing the ISO8601 timestamp of the most recently
/// scheduled reminder notification. Used to compute delayMinutes in all
/// ReminderResponse paths.
const String kLastReminderSentAtKey = 'last_reminder_sent_at';

/// SharedPreferences key for the pending ReminderResponse queue.
/// Written by notification callbacks; flushed by Splash Step 4.6.
const String kPendingReminderResponsesKey = 'pending_reminder_responses';

/// SharedPreferences key storing the ISO8601 sentAt timestamp of the last
/// notification for which a ReminderResponse has already been recorded.
/// Guards against double-recording across the 4 response paths.
const String kLastResponseRecordedAtKey = 'last_response_recorded_at';

// ── Fun Facts (Short Form) ───────────────────────────────────────────────────
/// 15 hydration facts in Indonesian — used on dashboard, notifications,
/// and onboarding for quick display.
const List<String> kHydrationFacts = [
  'Tubuh manusia terdiri dari sekitar 60% air.',
  'Dehidrasi ringan 1–2% sudah dapat menurunkan konsentrasi.',
  'Otak manusia mengandung sekitar 75% air.',
  'Air putih tidak mengandung kalori — minuman terbaik untuk hidrasi.',
  'Rasa haus muncul setelah tubuh sudah mulai dehidrasi.',
  'Minum air sebelum makan dapat membantu mengontrol porsi makan.',
  'Ginjal membutuhkan cukup air untuk menyaring limbah dari darah.',
  'Warna urin kuning pucat menandakan hidrasi yang baik.',
  'Kafein bersifat diuretik ringan — imbangi dengan air putih.',
  'Tubuh kehilangan air melalui napas, keringat, dan urin setiap hari.',
  'Sel otak sangat sensitif terhadap perubahan kadar air tubuh.',
  'Minum air dingin dapat membakar sedikit kalori untuk menghangatkannya.',
  'Otot yang terhidrasi dengan baik lebih tahan terhadap kram.',
  'Air membantu mengatur suhu tubuh melalui proses berkeringat.',
  'Konsumsi air yang cukup dapat membantu mencegah batu ginjal.',
];

// ── Hydration Articles (Full Content) ────────────────────────────────────────

/// Data class for education articles displayed on the Education screen.
class HydrationArticle {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String category; // 'manfaat' | 'mitos' | 'tips' | 'sains'
  final String emoji;

  const HydrationArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.emoji,
  });
}

/// Education articles — content to be provided by researcher.
const List<HydrationArticle> kHydrationArticles = [
  // ── SAINS ────────────────────────────────────────────────────────────────
  HydrationArticle(
    id: 'sains_1',
    title: '60% Tubuh Anda Adalah Air',
    summary: 'Tubuh manusia dewasa rata-rata terdiri dari sekitar 60% air. Persentase ini bahkan lebih tinggi pada bayi dan anak-anak.',
    body: 'Tubuh manusia dewasa rata-rata terdiri dari sekitar 60% air. Persentase ini bahkan lebih tinggi pada bayi dan anak-anak, bisa mencapai 75-80%. Air tidak hanya ada di darah, tetapi juga di otak (75%), jantung (75%), paru-paru (86%), ginjal (83%), bahkan tulang yang keras sekalipun mengandung 22% air. Setiap sel, jaringan, dan organ dalam tubuh Anda membutuhkan air agar bisa berfungsi dengan normal. Tanpa air yang cukup, seluruh sistem tubuh akan terganggu.',
    category: 'sains',
    emoji: '🔬',
  ),
  HydrationArticle(
    id: 'sains_2',
    title: 'Kebutuhan Air Setiap Orang Berbeda',
    summary: 'Rekomendasi umum "8 gelas sehari" memang mudah diingat, tapi kebutuhan air setiap orang berbeda-beda tergantung berbagai faktor.',
    body: 'Rekomendasi umum "8 gelas sehari" memang mudah diingat, tapi kebutuhan air setiap orang berbeda-beda. Faktor yang mempengaruhi antara lain: berat badan, usia, jenis kelamin, tingkat aktivitas fisik, suhu lingkungan, dan kondisi kesehatan. Cara paling akurat untuk menghitung kebutuhan air harian adalah dengan rumus: Berat Badan (kg) × 30 ml. Contohnya, jika berat badan Anda 60 kg, maka Anda membutuhkan sekitar 1.800 ml atau setara dengan 7-8 gelas air per hari. Orang yang aktif berolahraga atau bekerja di luar ruangan membutuhkan lebih banyak lagi.',
    category: 'sains',
    emoji: '⚖️',
  ),
  HydrationArticle(
    id: 'sains_3',
    title: 'Air Membantu Detoksifikasi Alami Tubuh',
    summary: 'Tubuh memiliki sistem detoksifikasi alami yang canggih, dan air adalah kunci utama untuk melarutkan dan mengeluarkan racun.',
    body: 'Tubuh memiliki sistem detoksifikasi alami yang sangat canggih, dan air adalah kuncinya. Racun-racun hasil metabolisme, seperti urea, kreatinin, dan asam urat, larut dalam air dan dikeluarkan melalui urine. Selain itu, racun juga keluar melalui keringat dan feses. Tanpa asupan air yang cukup, racun-racun ini akan tetap berada di dalam tubuh dan bisa merusak sel-sel sehat. Minum air putih yang cukup, terutama di pagi hari setelah bangun tidur, sangat efektif untuk membantu proses pembersihan organ-organ tubuh. Semakin banyak air yang Anda minum (dalam dosis wajar), semakin banyak racun yang dikeluarkan.',
    category: 'sains',
    emoji: '🧪',
  ),
  HydrationArticle(
    id: 'sains_4',
    title: 'Air Mengatur Suhu Tubuh',
    summary: 'Air berperan krusial dalam mengatur suhu tubuh melalui proses penguapan keringat untuk mencegah sengatan panas.',
    body: 'Salah satu fungsi air yang paling penting namun sering tidak disadari adalah mengatur suhu tubuh. Ketika tubuh Anda kepanasan (misalnya karena olahraga, demam, atau cuaca panas), kelenjar keringat akan mengeluarkan air ke permukaan kulit. Saat air keringat menguap, tubuh Anda menjadi dingin. Proses ini hanya bisa berjalan jika tubuh memiliki cukup air. Jika Anda dehidrasi, tubuh tidak bisa berkeringat dengan baik, sehingga suhu tubuh bisa naik secara berbahaya, menyebabkan heat stroke (sengatan panas) yang bisa berakibat fatal. Minum air yang cukup sangat penting, terutama saat cuaca panas atau saat beraktivitas fisik berat.',
    category: 'sains',
    emoji: '🌡️',
  ),

  // ── FAKTA UNIK ────────────────────────────────────────────────────────────
  HydrationArticle(
    id: 'fakta_1',
    title: 'Haus Berarti Anda Sudah Terlambat',
    summary: 'Rasa haus muncul ketika tubuh sudah kehilangan 1-2% cairan tubuh, menandakan Anda sudah mengalami dehidrasi ringan.',
    body: 'Banyak orang mengira rasa haus adalah tanda bahwa tubuh mulai membutuhkan air. Padahal, rasa haus muncul ketika tubuh sudah kehilangan 1-2% dari total cairan tubuh. Ini berarti Anda sudah memasuki fase dehidrasi ringan. Pada tahap ini, konsentrasi mulai menurun, tubuh terasa lemas, mulut kering, dan suasana hati bisa menjadi mudah marah. Oleh karena itu, jangan tunggu haus untuk minum. Biasakan minum air secara teratur sepanjang hari agar tubuh tetap terhidrasi optimal.',
    category: 'fakta_unik',
    emoji: '🏜️',
  ),
  HydrationArticle(
    id: 'fakta_2',
    title: 'Cara Termudah Mengetahui Cukup Minum: Lihat Warna Urine',
    summary: 'Warna urine adalah indikator termudah untuk memantau status hidrasi tubuh Anda tanpa memerlukan alat canggih.',
    body: 'Anda tidak perlu alat canggih untuk mengetahui apakah tubuh Anda terhidrasi dengan baik. Cukup lihat warna urine Anda. Kriteria sederhananya:\n\n· Kuning muda pucat atau bening → Selamat! Tubuh Anda terhidrasi dengan sangat baik.\n· Kuning terang → Masih cukup, tapi sebaiknya segera minum.\n· Kuning gelap/pekat seperti teh atau jus apel → Tanda bahaya! Anda kekurangan cairan dan harus segera minum air putih.\n· Oranye atau coklat → Dehidrasi berat. Segera minum air dan konsultasikan ke dokter jika berlanjut.\n\nSemakin gelap warna urine Anda, semakin pekat limbah di dalam tubuh, dan semakin berat kerja ginjal Anda.',
    category: 'fakta_unik',
    emoji: '🎨',
  ),
  HydrationArticle(
    id: 'fakta_3',
    title: 'Pengetahuan Baik Membentuk Perilaku Minum yang Baik',
    summary: 'Pengetahuan yang baik tentang manfaat air putih terbukti dapat membentuk perilaku dan kebiasaan minum yang lebih sehat.',
    body: 'Penelitian membuktikan bahwa semakin tinggi pengetahuan seseorang tentang manfaat air putih, semakin baik pula perilaku minumnya. Siswa yang tahu bahwa air putih mencegah dehidrasi, melancarkan pencernaan, dan melindungi ginjal cenderung minum lebih banyak air setiap hari dibandingkan siswa yang pengetahuannya rendah. Sayangnya, banyak remaja yang pengetahuannya masih minim. Mereka hanya minum saat haus, sering mengganti air putih dengan minuman manis, atau bahkan tidak minum sama sekali saat makan. Oleh karena itu, edukasi tentang manfaat air putih harus terus digalakkan, mulai dari sekolah, keluarga, hingga lingkungan masyarakat.',
    category: 'fakta_unik',
    emoji: '🎓',
  ),
  HydrationArticle(
    id: 'fakta_4',
    title: 'Sikap Positif Juga Penting, Tapi Tidak Cukup',
    summary: 'Tahu manfaat air putih saja tidak cukup; diperlukan kemauan dan kebiasaan konsisten seperti membawa botol minum sendiri.',
    body: 'Memiliki sikap positif terhadap air putih (misalnya setuju bahwa air putih itu sehat) memang baik, tetapi belum tentu membuat seseorang benar-benar minum cukup. Banyak orang tahu bahwa air putih itu penting, tetapi tetap malas meminumnya karena alasan "tidak enak", "hambar", atau "lupa". Hal ini menunjukkan bahwa sikap positif saja tidak cukup. Yang diperlukan adalah kebiasaan dan kemauan. Mulailah dengan membawa botol minum (tumbler) ke mana pun Anda pergi, memasang pengingat minum di ponsel, atau membiasakan minum satu gelas air setiap bangun tidur, sebelum makan, dan sebelum tidur. Kebiasaan kecil yang dilakukan konsisten akan membawa perubahan besar bagi kesehatan Anda.',
    category: 'fakta_unik',
    emoji: '✅',
  ),
  HydrationArticle(
    id: 'fakta_5',
    title: 'Edukasi Air Putih Harus Dimulai Sejak Usia Dini',
    summary: 'Mengajarkan manfaat air putih sejak usia dini sangat penting untuk mencegah gangguan konsentrasi dan masalah kesehatan jangka panjang.',
    body: 'Anak-anak usia sekolah dasar (SD/MI) cenderung sangat aktif bergerak dan bermain, sehingga cairan tubuh mereka lebih cepat keluar melalui keringat. Jika tidak cukup minum, mereka berisiko mengalami dehidrasi yang bisa mengganggu konsentrasi belajar, menurunkan prestasi akademik, bahkan menyebabkan masalah kesehatan jangka panjang seperti gangguan ginjal. Sayangnya, anak-anak lebih suka minuman manis berwarna-warni daripada air putih. Oleh karena itu, orang tua dan guru memiliki peran yang sangat penting. Mereka harus mengajarkan manfaat air putih sejak dini, memberi contoh dengan minum air putih di depan anak, menyediakan air putih yang mudah dijangkau, serta menerapkan pendidikan karakter seperti "tanggung jawab menjaga kesehatan diri sendiri".',
    category: 'fakta_unik',
    emoji: '🧒',
  ),

  // ── KESEHATAN ─────────────────────────────────────────────────────────────
  HydrationArticle(
    id: 'sehat_1',
    title: 'Air Meningkatkan Konsentrasi dan Fungsi Otak',
    summary: 'Dehidrasi ringan dapat mengganggu fungsi kognitif, konsentrasi, dan suasana hati karena otak sangat sensitif terhadap kadar air.',
    body: 'Otak Anda sangat sensitif terhadap perubahan kadar air. Penelitian menunjukkan bahwa dehidrasi ringan saja (kehilangan 1-2% cairan tubuh) sudah cukup untuk mengganggu fungsi kognitif. Gejalanya meliputi: sulit fokus, daya ingat menurun, waktu reaksi melambat, dan kemampuan berpikir menjadi tidak tajam. Bahkan, dehidrasi bisa membuat Anda merasa cemas dan mudah stres. Sebaliknya, ketika tubuh terhidrasi dengan baik, otak bekerja lebih optimal, konsentrasi meningkat, dan suasana hati menjadi lebih stabil. Minumlah air putih secara teratur, terutama saat belajar atau bekerja.',
    category: 'kesehatan',
    emoji: '🧠',
  ),
  HydrationArticle(
    id: 'sehat_2',
    title: 'Kurang Minum Bisa Merusak Ginjal',
    summary: 'Ginjal membutuhkan air yang cukup untuk menyaring limbah darah. Kekurangan cairan berisiko menyebabkan batu ginjal hingga gagal ginjal.',
    body: 'Ginjal adalah organ yang bertugas menyaring limbah dan racun dari darah. Setiap hari, ginjal memproses sekitar 120-150 liter darah untuk menghasilkan 1-2 liter urine. Proses ini membutuhkan air yang cukup. Jika tubuh kekurangan cairan, ginjal akan kesulitan membuang racun, sehingga zat-zat berbahaya menumpuk di dalam tubuh. Dalam jangka pendek, ini bisa menyebabkan infeksi saluran kemih. Dalam jangka panjang, risiko batu ginjal dan gagal ginjal kronis meningkat drastis. Sayangnya, banyak remaja dan dewasa muda yang sudah harus menjalani cuci darah karena gagal ginjal akibat kurang minum air putih.',
    category: 'kesehatan',
    emoji: '🩺',
  ),
  HydrationArticle(
    id: 'sehat_3',
    title: 'Air Mencegah Sembelit dan Melancarkan Pencernaan',
    summary: 'Air membantu memecah makanan dan melunakkan feses, menjadikannya kunci utama untuk mencegah sembelit dan melancarkan pencernaan.',
    body: 'Sistem pencernaan Anda membutuhkan air untuk bekerja dengan lancar. Air membantu memecah makanan yang Anda konsumsi, sehingga nutrisi lebih mudah diserap oleh usus. Air juga berperan dalam pembentukan air liur dan getah lambung. Selain itu, air melunakkan feses sehingga mudah dikeluarkan. Kurang minum adalah salah satu penyebab utama sembelit (konstipasi). Jika Anda sering mengalami susah buang air besar, perut kembung, atau wasir, coba periksa apakah Anda sudah cukup minum air putih setiap hari. Minum air hangat di pagi hari juga dikenal ampuh melancarkan buang air besar.',
    category: 'kesehatan',
    emoji: '🍏',
  ),
  HydrationArticle(
    id: 'sehat_4',
    title: 'Air Membuat Kulit Lebih Sehat dan Awet Muda',
    summary: 'Air menjaga kelembaban dan elastisitas kulit dari dalam, membantu kulit tetap sehat, kenyal, dan bercahaya.',
    body: 'Kulit adalah organ terbesar di tubuh Anda, dan kulit yang sehat dimulai dari dalam. Air membantu menjaga kelembaban alami kulit, meningkatkan elastisitas, dan mencegah kekeringan. Ketika tubuh kekurangan cairan, kulit akan terlihat kusam, kering, mudah mengelupas, dan garis-garis halus (kerutan) menjadi lebih cepat muncul. Sebaliknya, kulit yang terhidrasi dengan baik akan terasa kenyal, lembab, dan bercahaya. Tidak ada krim atau serum yang bisa menggantikan manfaat air putih dari dalam. Jadi, jika Anda ingin kulit sehat dan awet muda, mulailah dengan minum air yang cukup setiap hari.',
    category: 'kesehatan',
    emoji: '✨',
  ),
  HydrationArticle(
    id: 'sehat_5',
    title: 'Air Membantu Menjaga Berat Badan Ideal',
    summary: 'Minum air putih sebelum makan dapat membantu mengontrol nafsu makan dan meningkatkan efisiensi metabolisme lemak tubuh.',
    body: 'Bagi Anda yang sedang berusaha menurunkan atau menjaga berat badan, air putih adalah sahabat terbaik. Penelitian menunjukkan bahwa minum air putih 30 menit sebelum makan dapat membantu Anda merasa kenyang lebih cepat, sehingga secara alami Anda akan makan lebih sedikit. Dalam sebuah studi, remaja putri yang minum 450 ml air sebelum makan selama 5 minggu mengalami penurunan persentase lemak tubuh yang signifikan. Selain itu, mengganti minuman manis (seperti soda, jus kemasan, atau teh manis) dengan air putih bisa mengurangi ratusan kalori setiap hari. Air putih juga membantu metabolisme lemak lebih efisien.',
    category: 'kesehatan',
    emoji: '🏃',
  ),
  HydrationArticle(
    id: 'sehat_6',
    title: 'Jauhi Minuman Manis, Perbanyak Air Putih',
    summary: 'Minuman manis mengandung gula tinggi yang berbahaya; air mineral murni adalah pilihan terbaik untuk hidrasi tubuh yang sehat.',
    body: 'Saat ini, banyak remaja dan orang dewasa lebih menyukai minuman manis, bersoda, berenergi, atau bahkan beralkohol dibandingkan air putih. Padahal, kebiasaan ini sangat berbahaya bagi kesehatan jangka panjang. Minuman manis mengandung gula tinggi yang bisa menyebabkan obesitas, diabetes, dan kerusakan gigi. Minuman bersoda dan berenergi juga bersifat diuretik (memperbanyak buang air kecil) sehingga justru membuat tubuh kehilangan cairan lebih cepat. Anggapan bahwa minuman lain bisa menggantikan air putih adalah kesalahan fatal. Tubuh Anda membutuhkan air putih mineral murni, bukan air yang sudah dicampur zat kimia, pewarna, atau pengawet.',
    category: 'kesehatan',
    emoji: '🥤',
  ),
];
// ── Profile Form Constants ────────────────────────────────────────────────────

/// Riwayat penyakit — multi-select research variable.
/// These values are stored as `List<String>` in UserProfile.riwayatPenyakit.
/// NOT used in hydration calculation — research data only.
const List<String> kMedicalConditions = [
  'diabetes_mellitus',
  'gagal_ginjal',
  'penyakit_jantung',
  'penyakit_hati_sirosis',
];

/// Display labels for each medical condition in kMedicalConditions.
const Map<String, String> kMedicalConditionLabels = {
  'diabetes_mellitus': 'Diabetes Mellitus',
  'gagal_ginjal': 'Gagal Ginjal',
  'penyakit_jantung': 'Penyakit Jantung / Gagal Jantung',
  'penyakit_hati_sirosis': 'Penyakit Hati (Sirosis)',
};

/// Level aktivitas — ordered from rendah to sangat_aktif.
const List<Map<String, String>> kActivityLevels = [
  {
    'value': 'rendah',
    'label': 'Rendah',
    'description': 'Duduk sepanjang hari, tidak berolahraga',
  },
  {
    'value': 'ringan',
    'label': 'Ringan',
    'description': 'Jalan kaki ringan, olahraga 1–2x/minggu',
  },
  {
    'value': 'sedang',
    'label': 'Sedang',
    'description': 'Olahraga 3–5x/minggu',
  },
  {
    'value': 'aktif',
    'label': 'Aktif',
    'description': 'Olahraga intensif setiap hari',
  },
  {
    'value': 'sangat_aktif',
    'label': 'Sangat Aktif',
    'description': 'Latihan berat / pekerjaan fisik berat',
  },
];

/// Letak geografis — dropdown options.
const List<Map<String, String>> kGeographicOptions = [
  {'value': 'dataran_rendah', 'label': 'Dataran Rendah'},
  {'value': 'dataran_tinggi', 'label': 'Dataran Tinggi'},
];

/// Disclaimer wording required on all hydration recommendation screens.
const String kHydrationDisclaimer =
    'Estimasi kebutuhan cairan harian berdasarkan data profil.\n'
    'Bukan penggantian saran medis profesional.';
