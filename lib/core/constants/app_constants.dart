/// Application-wide constants for the Personal Hydration Tracker.
library;

// ── Route Names ──────────────────────────────────────────────────────────────

const String kRouteSplash = '/';
const String kRouteOnboarding = '/onboarding';
const String kRouteProfileSetup = '/profile-setup';
const String kRouteDashboard = '/dashboard';
const String kRouteEducation = '/education';
const String kRouteProgress = '/progress';
const String kRouteAchievements = '/achievements';

// ── Hydration Defaults ───────────────────────────────────────────────────────

/// Minimum daily target in ml (clamp lower bound).
const int kTargetClampMin = 1500;

/// Maximum daily target in ml (clamp upper bound).
const int kTargetClampMax = 4000;

/// Reminder active window start hour (inclusive).
const int kReminderWindowStart = 7; // 07:00

/// Reminder active window end hour (inclusive).
const int kReminderWindowEnd = 21; // 21:00

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
/// Do NOT generate placeholder content. Leave empty until researcher supplies
/// the actual articles.
// TODO(researcher): Add 10–15 HydrationArticle entries before implementing F-09.
const List<HydrationArticle> kHydrationArticles = [];
