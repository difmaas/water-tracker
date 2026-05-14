import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/hydration_provider.dart';
import '../../../../providers/profile_provider.dart';
import 'widgets/progress_ring.dart';
import 'widgets/quick_add_buttons.dart';
import 'widgets/fun_fact_card.dart';
import 'widgets/hydration_log_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydrationState = ref.watch(hydrationProvider);
    
    // We get month string in Indonesian manually for simplicity or use intl if available.
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dateString = '${now.day} ${months[now.month - 1]}';

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
        ),
        body: hydrationState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // Header Area
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hari ini, $dateString',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Halo, ${hydrationState.userName}! 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Streak Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            hydrationState.currentStreak > 0
                                ? '🔥 ${hydrationState.currentStreak} Hari Berturut-turut'
                                : '🔥 Mulai streak-mu hari ini!',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notification Banner
                    if (!hydrationState.notificationPermissionGranted)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Izin notifikasi belum diberikan. Pengingat minum air tidak akan aktif.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Progress Ring
                    const Center(child: ProgressRing()),
                    const SizedBox(height: 32),

                    // Quick Add Buttons
                    const QuickAddButtons(),
                    const SizedBox(height: 24),

                    // Fun Fact
                    const FunFactCard(),
                    const SizedBox(height: 32),

                    // Log List Header
                    const Text(
                      'Catatan Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Log List
                    if (hydrationState.todayLogs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Belum ada catatan hari ini.\nYuk minum air!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: hydrationState.todayLogs
                              .map((log) => HydrationLogTile(log: log))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Segera hadir')),
            );
          },
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          child: const Icon(Icons.school),
        ),
      ),
    );
  }
}
