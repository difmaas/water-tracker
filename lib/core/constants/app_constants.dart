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
    'Data ini hanya digunakan untuk menyesuaikan pengalaman di aplikasi.';

// ── Hydration Defaults ───────────────────────────────────────────────────────

/// Minimum daily target in ml (clamp lower bound).
const int kTargetClampMin = 1500;

/// Maximum daily target in ml (clamp upper bound).
const int kTargetClampMax = 4000;

/// Shared preset volumes used by add and edit hydration log flows.
const List<int> kHydrationVolumePresets = [250, 500, 750, 1000];

/// Reminder active window start hour (inclusive).
const int kReminderWindowStart = 7; // 07:00

/// Reminder active window end hour (inclusive).
const int kReminderWindowEnd = 21; // 21:00

/// IDs for notifications.
class NotificationIds {
  static const int legacyRegular = 42;
  static const int reEngagement = 43;
  static const int test = 44;
  static const int regularReminderBase = 10000;
  static const int regularReminderMaxSlots = 32;
}

// ── Reminder Response Tracking Keys (F-08) ───────────────────────────────────

/// SharedPreferences key storing the ISO8601 timestamp of the most recently
/// scheduled reminder notification. Used to compute delayMinutes in all
/// ReminderResponse paths.
const String kLastReminderSentAtKey = 'last_reminder_sent_at';

/// SharedPreferences key storing pending regular reminder notification IDs.
/// Used to cancel all scheduled interval slots before rebuilding the schedule.
const String kScheduledRegularReminderIdsKey = 'scheduled_regular_reminder_ids';

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

// ── Hydration Articles (Full Content) ────────────────────────────────────────────────

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
    summary:
        'Tubuh manusia dewasa rata-rata terdiri dari sekitar 60% air. Persentase ini bahkan lebih tinggi pada bayi dan anak-anak.',
    body:
        'Tubuh manusia dewasa rata-rata terdiri dari sekitar 60% air. Persentase ini bahkan lebih tinggi pada bayi dan anak-anak, yang bisa mencapai 75–80%.\n\n'
        'Air tidak hanya terkandung di dalam darah, tetapi juga di otak (75%), jantung (75%), paru-paru (86%), ginjal (83%), bahkan tulang yang keras sekalipun mengandung sekitar 22% air.\n\n'
        'Setiap sel, jaringan, dan organ dalam tubuh Anda membutuhkan air agar dapat berfungsi secara normal. Tanpa air yang cukup, seluruh sistem tubuh Anda akan terganggu.',
    category: 'sains',
    emoji: '🔬',
  ),
  HydrationArticle(
    id: 'sains_2',
    title: 'Kebutuhan Air Setiap Orang Berbeda',
    summary:
        'Rekomendasi umum "8 gelas sehari" memang mudah diingat, tapi kebutuhan air setiap orang berbeda-beda tergantung berbagai faktor.',
    body:
        'Rekomendasi umum "8 gelas sehari" memang mudah diingat, tetapi kebutuhan air setiap orang sebenarnya berbeda-beda. Faktor yang memengaruhi antara lain: berat badan, usia, jenis kelamin, tingkat aktivitas fisik, suhu lingkungan, dan kondisi kesehatan.\n\n'
        'Cara paling akurat untuk menghitung kebutuhan air harian adalah dengan rumus: Berat Badan (kg) × 30 ml.\n\n'
        'Sebagai contoh, jika berat badan Anda 60 kg, Anda membutuhkan sekitar 1.800 ml air atau setara dengan 7–8 gelas per hari. Orang yang aktif berolahraga atau bekerja di luar ruangan tentu membutuhkan asupan yang lebih banyak.',
    category: 'sains',
    emoji: '⚖️',
  ),
  HydrationArticle(
    id: 'sains_3',
    title: 'Air Membantu Detoksifikasi Alami Tubuh',
    summary:
        'Tubuh memiliki sistem detoksifikasi alami yang canggih, dan air adalah kunci utama untuk melarutkan dan mengeluarkan racun.',
    body:
        'Tubuh memiliki sistem detoksifikasi alami yang sangat canggih, dan air adalah kuncinya.\n\n'
        'Racun hasil metabolisme seperti urea, kreatinin, dan asam urat akan larut dalam air sebelum dikeluarkan melalui urine. Selain itu, sisa metabolisme juga dikeluarkan melalui keringat dan feses.\n\n'
        'Tanpa asupan air yang cukup, racun-racun ini akan tetap menumpuk di dalam tubuh dan berpotensi merusak sel-sel yang sehat.\n\n'
        'Minum air putih yang cukup, terutama di pagi hari setelah bangun tidur, sangat efektif untuk membantu proses pembersihan organ dalam tubuh. Semakin teratur Anda minum air (dalam batas wajar), semakin efisien proses pengeluaran racun tersebut.',
    category: 'sains',
    emoji: '🧪',
  ),
  HydrationArticle(
    id: 'sains_4',
    title: 'Air Mengatur Suhu Tubuh',
    summary:
        'Air berperan krusial dalam mengatur suhu tubuh melalui proses penguapan keringat untuk mencegah sengatan panas.',
    body:
        'Salah satu fungsi air yang paling penting tetapi sering tidak disadari adalah mengatur suhu tubuh.\n\n'
        'Ketika tubuh Anda kepanasan (misalnya akibat olahraga, demam, atau cuaca panas), kelenjar keringat akan mengeluarkan cairan ke permukaan kulit. Saat keringat menguap, suhu tubuh Anda akan menurun secara alami. Proses pendinginan ini hanya bisa berjalan optimal jika tubuh memiliki cadangan air yang cukup.\n\n'
        'Jika Anda mengalami dehidrasi, tubuh tidak dapat menghasilkan keringat dengan baik sehingga suhu tubuh bisa meningkat drastis. Kondisi ini dapat memicu heat stroke (sengatan panas) yang berbahaya. Oleh karena itu, minumlah air yang cukup sebelum, selama, dan setelah beraktivitas.',
    category: 'sains',
    emoji: '🌡️',
  ),

  // ── FAKTA UNIK ────────────────────────────────────────────────────────────
  HydrationArticle(
    id: 'fakta_1',
    title: 'Rasa Haus Berarti Anda Sudah Terlambat',
    summary:
        'Rasa haus muncul ketika tubuh sudah kehilangan 1-2% cairan tubuh, menandakan Anda sudah mengalami dehidrasi ringan.',
    body:
        'Banyak orang mengira rasa haus adalah sinyal awal bahwa tubuh mulai memerlukan air. Padahal, rasa haus baru muncul ketika tubuh telah kehilangan 1–2% dari total cairan tubuh. Ini menandakan bahwa Anda sebenarnya sudah mengalami dehidrasi ringan.\n\n'
        'Pada tahap dehidrasi ringan ini, konsentrasi Anda mulai menurun, tubuh terasa lemas, mulut terasa kering, dan suasana hati dapat menjadi lebih sensitif atau mudah marah.\n\n'
        'Oleh karena itu, jangan menunggu hingga rasa haus datang untuk minum air. Biasakanlah minum air putih secara teratur sepanjang hari agar tubuh tetap terhidrasi secara optimal.',
    category: 'fakta_unik',
    emoji: '🏜️',
  ),
  HydrationArticle(
    id: 'fakta_2',
    title: 'Cara Termudah Mengetahui Cukup Minum: Lihat Warna Urine',
    summary:
        'Warna urine adalah indikator termudah untuk memantau status hidrasi tubuh Anda tanpa memerlukan alat canggih.',
    body:
        'Anda tidak memerlukan alat medis yang canggih untuk memantau apakah tubuh Anda sudah mendapatkan cukup air. Cukup perhatikan warna urine Anda saat buang air kecil. Berikut adalah kriteria sederhananya:\n\n'
        '· Kuning muda pucat atau bening → Selamat! Tubuh Anda sudah terhidrasi dengan sangat baik.\n'
        '· Kuning terang → Status hidrasi Anda masih cukup, tetapi sebaiknya Anda segera minum air.\n'
        '· Kuning gelap atau pekat seperti teh → Tanda peringatan! Anda kekurangan cairan dan harus segera minum air putih.\n'
        '· Oranye atau kecokelatan → Menandakan dehidrasi berat. Segera penuhi kebutuhan air Anda, dan konsultasikan ke dokter jika kondisi ini terus berlanjut.\n\n'
        'Semakin gelap warna urine, semakin tinggi konsentrasi limbah yang menumpuk di dalam tubuh, yang berarti ginjal Anda harus bekerja jauh lebih keras.',
    category: 'fakta_unik',
    emoji: '🎨',
  ),
  HydrationArticle(
    id: 'fakta_3',
    title: 'Pengetahuan Baik Membentuk Perilaku Minum yang Baik',
    summary:
        'Pengetahuan yang baik tentang manfaat air putih terbukti dapat membentuk perilaku dan kebiasaan minum yang lebih sehat.',
    body:
        'Studi kesehatan menunjukkan bahwa tingkat pengetahuan seseorang mengenai manfaat air putih memengaruhi perilaku minum harian mereka secara positif. Remaja yang memahami bahwa air putih berguna untuk mencegah dehidrasi, melancarkan pencernaan, serta memelihara fungsi ginjal cenderung mengonsumsi lebih banyak air putih setiap hari dibandingkan dengan mereka yang kurang memahami hal tersebut.\n\n'
        'Sayangnya, masih banyak remaja yang belum menyadari pentingnya hidrasi teratur. Mereka cenderung baru minum saat merasa sangat haus, atau justru sering mengganti air putih dengan minuman manis yang tinggi gula.\n\n'
        'Oleh karena itu, edukasi mengenai manfaat air putih perlu terus ditingkatkan, baik di lingkungan sekolah, keluarga, maupun komunitas remaja.',
    category: 'fakta_unik',
    emoji: '🎓',
  ),
  HydrationArticle(
    id: 'fakta_4',
    title: 'Sikap Positif Juga Penting, Tapi Tidak Cukup',
    summary:
        'Tahu manfaat air putih saja tidak cukup; diperlukan kemauan dan kebiasaan konsisten seperti membawa botol minum sendiri.',
    body:
        'Memiliki sikap yang positif terhadap konsumsi air putih (seperti setuju bahwa air putih itu menyehatkan) adalah langkah awal yang baik. Namun, sikap saja belum tentu membuat seseorang otomatis minum secara cukup. Banyak orang sadar bahwa air putih penting, tetapi tetap malas meminumnya dengan alasan hambar atau sering lupa.\n\n'
        'Hal ini membuktikan bahwa kesadaran saja tidaklah cukup jika tidak disertai dengan tindakan nyata dan pembiasaan diri.\n\n'
        'Cobalah memulainya dengan langkah praktis, seperti membawa botol minum sendiri (tumbler) ke mana pun pergi, memasang alarm pengingat minum di ponsel, atau membiasakan diri minum satu gelas air setiap kali bangun tidur, sebelum makan, dan menjelang tidur. Kebiasaan kecil yang dilakukan secara konsisten akan membawa dampak besar bagi kesehatan Anda.',
    category: 'fakta_unik',
    emoji: '✅',
  ),
  HydrationArticle(
    id: 'fakta_5',
    title: 'Edukasi Air Putih Harus Dimulai Sejak Usia Dini',
    summary:
        'Mengajarkan manfaat air putih sejak usia dini sangat penting untuk mencegah gangguan konsentrasi dan masalah kesehatan jangka panjang.',
    body:
        'Anak-anak dan remaja cenderung sangat aktif beraktivitas dan bermain, sehingga cairan tubuh mereka lebih cepat berkurang melalui keringat.\n\n'
        'Jika kebutuhan cairan tidak terpenuhi, mereka rentan mengalami dehidrasi yang dapat mengganggu konsentrasi belajar, menurunkan fokus akademik, bahkan memicu masalah kesehatan jangka panjang seperti gangguan ginjal. Sayangnya, mereka sering kali lebih memilih minuman manis yang berwarna-warni dibandingkan air putih.\n\n'
        'Di sinilah peran penting orang tua dan pendidik untuk memberikan contoh nyata dengan rutin minum air putih, menyediakan akses air minum yang mudah dijangkau, serta mengajarkan kebiasaan bertanggung jawab dalam menjaga kesehatan diri sendiri sejak dini.',
    category: 'fakta_unik',
    emoji: '🧒',
  ),

  // ── KESEHATAN ─────────────────────────────────────────────────────────────
  HydrationArticle(
    id: 'sehat_1',
    title: 'Air Meningkatkan Konsentrasi dan Fungsi Otak',
    summary:
        'Dehidrasi ringan dapat mengganggu fungsi kognitif, konsentrasi, dan suasana hati karena otak sangat sensitif terhadap kadar air.',
    body:
        'Otak manusia sangat sensitif terhadap perubahan kadar air. Banyak studi menunjukkan bahwa dehidrasi ringan (kehilangan hanya 1–2% cairan tubuh) sudah cukup untuk mengganggu fungsi kognitif otak Anda.\n\n'
        'Gejala yang sering muncul meliputi kesulitan untuk fokus, penurunan daya ingat jangka pendek, respon yang melambat, serta mudah merasa lelah. Bahkan, kekurangan cairan juga dapat memperburuk suasana hati dan memicu kecemasan.\n\n'
        'Sebaliknya, ketika kebutuhan cairan terpenuhi dengan baik, aliran darah ke otak menjadi lebih lancar, konsentrasi meningkat, dan fungsi kognitif berjalan optimal. Oleh karena itu, selalu sediakan air putih di meja belajar atau tempat kerja Anda.',
    category: 'kesehatan',
    emoji: '🧠',
  ),
  HydrationArticle(
    id: 'sehat_2',
    title: 'Kurang Minum Bisa Merusak Ginjal',
    summary:
        'Ginjal membutuhkan air yang cukup untuk menyaring limbah darah. Kekurangan cairan berisiko menyebabkan batu ginjal hingga gagal ginjal.',
    body:
        'Ginjal bertugas menyaring limbah, racun, dan kelebihan cairan dari dalam darah untuk dikeluarkan sebagai urine. Agar dapat menjalankan proses penyaringan ini secara efisien, ginjal membutuhkan asupan air yang cukup setiap hari.\n\n'
        'Apabila tubuh kekurangan cairan, ginjal harus bekerja lebih keras dan memekatkan urine, sehingga zat-zat sisa metabolisme dapat mengendap di saluran kemih.\n\n'
        'Dalam jangka pendek, hal ini bisa memicu infeksi saluran kemih. Sementara dalam jangka panjang, risiko terbentuknya batu ginjal hingga gagal ginjal kronis akan meningkat secara signifikan.\n\n'
        'Membiasakan diri minum air putih yang cukup adalah cara termudah dan paling efektif untuk menjaga kesehatan ginjal Anda agar terhindar dari penyakit berat di masa depan.',
    category: 'kesehatan',
    emoji: '🩺',
  ),
  HydrationArticle(
    id: 'sehat_3',
    title: 'Air Mencegah Sembelit dan Melancarkan Pencernaan',
    summary:
        'Air membantu memecah makanan dan melunakkan feses, menjadikannya kunci utama untuk mencegah sembelit dan melancarkan pencernaan.',
    body:
        'Sistem pencernaan Anda memerlukan cairan yang cukup agar dapat berfungsi secara optimal. Air membantu memecah makanan yang masuk ke tubuh sehingga zat gizi atau nutrisinya dapat diserap usus dengan mudah.\n\n'
        'Selain itu, air berfungsi melunakkan konsistensi feses agar lebih mudah dikeluarkan. Kurang minum merupakan salah satu penyebab utama terjadinya sembelit (konstipasi).\n\n'
        'Jika Anda sering mengalami kesulitan buang air besar atau perut kembung, cobalah untuk meningkatkan asupan air putih harian Anda. Membiasakan minum segelas air hangat di pagi hari juga sangat dianjurkan untuk menstimulasi pencernaan yang sehat.',
    category: 'kesehatan',
    emoji: '🍏',
  ),
  HydrationArticle(
    id: 'sehat_4',
    title: 'Air Membuat Kulit Lebih Sehat dan Awet Muda',
    summary:
        'Air menjaga kelembaban dan elastisitas kulit dari dalam, membantu kulit tetap sehat, kenyal, dan bercahaya.',
    body:
        'Kulit merupakan organ terluar yang melindungi tubuh Anda, dan keindahan serta kesehatannya sangat bergantung pada hidrasi dari dalam. Air membantu menjaga kelembutan dan kelembapan alami kulit, meningkatkan elastisitas, serta mencegah kulit menjadi kering dan kasar.\n\n'
        'Ketika Anda kekurangan cairan, kulit akan terlihat lebih kusam, kering, mudah bersisik, dan garis-garis halus dapat tampak lebih jelas.\n\n'
        'Sebaliknya, hidrasi yang cukup akan membantu kulit Anda tetap kenyal, lembap, dan tampak lebih segar secara alami. Mulailah merawat kulit Anda dari hal mendasar dengan minum air putih yang cukup setiap hari.',
    category: 'kesehatan',
    emoji: '✨',
  ),
  HydrationArticle(
    id: 'sehat_5',
    title: 'Air Membantu Menjaga Berat Badan Ideal',
    summary:
        'Minum air putih sebelum makan dapat membantu mengontrol nafsu makan dan meningkatkan efisiensi metabolisme lemak tubuh.',
    body:
        'Bagi Anda yang ingin menjaga atau mencapai berat badan ideal, air putih adalah pendukung yang sangat baik. Studi menunjukkan bahwa membiasakan minum air putih sekitar 30 menit sebelum makan dapat meningkatkan rasa kenyang lebih awal, sehingga membantu mengontrol porsi makan secara alami.\n\n'
        'Dalam sebuah studi ilmiah, remaja putri yang rutin minum 450 ml air sebelum makan utama selama 5 minggu mengalami penurunan berat badan dan persentase lemak tubuh yang cukup berarti.\n\n'
        'Selain itu, mengganti konsumsi minuman kemasan atau bersoda yang tinggi kalori dengan air mineral murni dapat memangkas asupan kalori harian secara signifikan serta mendukung kelancaran metabolisme tubuh.',
    category: 'kesehatan',
    emoji: '🏃',
  ),
  HydrationArticle(
    id: 'sehat_6',
    title: 'Jauhi Minuman Manis, Perbanyak Air Putih',
    summary:
        'Minuman manis mengandung gula tinggi yang berbahaya; air mineral murni adalah pilihan terbaik untuk hidrasi tubuh yang sehat.',
    body:
        'Saat ini, banyak remaja dan orang dewasa lebih menyukai minuman manis, bersoda, atau minuman kemasan berenergi dibandingkan dengan air putih biasa. Padahal, kebiasaan tersebut memiliki risiko tinggi bagi kesehatan dalam jangka panjang.\n\n'
        'Minuman manis mengandung kadar gula yang tinggi yang dapat memicu kelebihan berat badan (obesitas), kerusakan pada gigi, hingga risiko diabetes melitus. Selain itu, beberapa jenis minuman bersoda dan berenergi memiliki sifat diuretik, yang justru membuat tubuh Anda membuang cairan lebih cepat.\n\n'
        'Anggapan bahwa minuman manis dapat sepenuhnya menggantikan fungsi air putih adalah kekeliruan yang besar. Tubuh Anda pada dasarnya membutuhkan air mineral murni yang bebas dari pemanis buatan, pewarna, atau zat pengawet kimia.',
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
  {'value': 'sedang', 'label': 'Sedang', 'description': 'Olahraga 3–5x/minggu'},
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
