import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';
import '../../../core/widgets/app_button.dart';

final achievementsProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile();
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(achievementsProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 24,
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Buku Medali',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lihat pencapaian dan streak harianmu',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Gagal memuat medali.',
            style: GoogleFonts.inter(color: Colors.black54),
          ),
        ),
        data: (profile) {
          final streak = profile?.currentStreak ?? 0;

          // Define all medals
          final medals = [
            (
              id: 'morning',
              title: 'Penyelamat Pagi',
              desc: 'Minum air putih sebelum jam 08:00 pagi.',
              emoji: '🌅',
              isUnlocked: true,
              color: const Color(0xFFFFE0B2),
              fg: const Color(0xFFE65100),
            ),
            (
              id: 'streak_3',
              title: 'Komitmen 3 Hari',
              desc: 'Target hidrasi tercapai 3 hari berturut-turut.',
              emoji: '🔥',
              isUnlocked: streak >= 3,
              color: const Color(0xFFFFCDD2),
              fg: const Color(0xFFB71C1C),
            ),
            (
              id: 'champion',
              title: 'Sang Juara',
              desc: 'Konsistensi hidrasi hari ini mencapai 100%.',
              emoji: '🏆',
              isUnlocked: true,
              color: const Color(0xFFFFF9C4),
              fg: const Color(0xFFF57F17),
            ),
            (
              id: 'notification',
              title: 'Kebiasaan Sehat',
              desc: 'Merespon 5 kali pengingat minum dalam satu hari.',
              emoji: '⚡',
              isUnlocked: false,
              color: const Color(0xFFE1BEE7),
              fg: const Color(0xFF4A148C),
            ),
            (
              id: 'night',
              title: 'Penjelajah Malam',
              desc: 'Minum air putih di atas jam 20:00 malam.',
              emoji: '🌌',
              isUnlocked: true,
              color: const Color(0xFFC5CAE9),
              fg: const Color(0xFF1A237E),
            ),
            (
              id: 'streak_7',
              title: 'Konsistensi Agung',
              desc: 'Target hidrasi tercapai 7 hari berturut-turut.',
              emoji: '👑',
              isUnlocked: streak >= 7,
              color: const Color(0xFFD1C4E9),
              fg: const Color(0xFF311B92),
            ),
          ];

          final unlockedCount = medals.where((m) => m.isUnlocked).length;

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () => ref.refresh(achievementsProfileProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                // Streak Card & Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencapaian Hidrasi',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Medali Diperoleh: $unlockedCount/${medals.length}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Color(0xFFFFB74D),
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$streak Hari Beruntun',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFFB74D),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏅',
                          style: GoogleFonts.inter(fontSize: 36),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Koleksi Medali Anda',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Medals Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: medals.length,
                  itemBuilder: (context, index) {
                    final m = medals[index];
                    return _MedalCard(
                      title: m.title,
                      desc: m.desc,
                      emoji: m.emoji,
                      isUnlocked: m.isUnlocked,
                      color: m.color,
                      fg: m.fg,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MedalCard extends StatefulWidget {
  final String title;
  final String desc;
  final String emoji;
  final bool isUnlocked;
  final Color color;
  final Color fg;

  const _MedalCard({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.isUnlocked,
    required this.color,
    required this.fg,
  });

  @override
  State<_MedalCard> createState() => _MedalCardState();
}

class _MedalCardState extends State<_MedalCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(28),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: widget.isUnlocked
                        ? widget.color
                        : Colors.black.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isUnlocked
                          ? widget.fg.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isUnlocked ? widget.emoji : '🔒',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      color: widget.isUnlocked ? null : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isUnlocked
                      ? 'Status: Terbuka Diperoleh'
                      : 'Status: Terkunci Belum Diperoleh',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: widget.isUnlocked
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.desc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.secondary(
                    label: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: widget.isUnlocked
                        ? widget.color
                        : Colors.black.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isUnlocked
                          ? widget.fg.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isUnlocked ? widget.emoji : '🔒',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      color: widget.isUnlocked ? null : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: widget.isUnlocked ? Colors.black87 : Colors.black38,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.desc,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
