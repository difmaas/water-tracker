import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'providers/onboarding_provider.dart';
import 'providers/isar_provider.dart';
import 'features/profile/data/user_profile_model.dart';
import 'features/dashboard/data/daily_summary_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 2. Initialize Isar (TODO: Re-enable after generator fix)
  // final dir = await getApplicationDocumentsDirectory();
  // final isar = await Isar.open(
  //   [UserProfileSchema, DailySummarySchema],
  //   directory: dir.path,
  // );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // isarProvider.overrideWithValue(isar),
      ],
      child: const HydrationApp(),
    ),
  );
}
