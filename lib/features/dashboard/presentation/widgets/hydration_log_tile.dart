import 'package:flutter/material.dart';
import '../../../../features/logging/data/hydration_log_model.dart';

class HydrationLogTile extends StatelessWidget {
  final HydrationLog log;

  const HydrationLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final timeString = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
    final sourceString = log.loggedVia == 'app' ? 'via app' : 'via notifikasi';

    return ListTile(
      leading: const Icon(Icons.water_drop, color: Color(0xFF1565C0)),
      title: Text('$timeString — ${log.volume}ml — $sourceString'),
      // No delete action in F-04
    );
  }
}
