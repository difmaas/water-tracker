import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/user_profile_model.dart';
import '../features/profile/domain/hydration_calculator.dart';
import 'onboarding_provider.dart';

class ProfileState {
  final String gender;
  final int age;
  final double weightKg;
  final String activityLevel;
  final int calculatedTargetMl;
  final int? manualTargetMl;
  final bool isLoading;

  ProfileState({
    this.gender = 'male',
    this.age = 25,
    this.weightKg = 70.0,
    this.activityLevel = 'moderate',
    this.calculatedTargetMl = 2750, // Default based on 70kg male moderate
    this.manualTargetMl,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? gender,
    int? age,
    double? weightKg,
    String? activityLevel,
    int? calculatedTargetMl,
    int? manualTargetMl,
    bool? isLoading,
  }) {
    return ProfileState(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      calculatedTargetMl: calculatedTargetMl ?? this.calculatedTargetMl,
      manualTargetMl: manualTargetMl ?? this.manualTargetMl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return ProfileState();
  }

  void updateGender(String gender) {
    state = state.copyWith(gender: gender);
    _recalculate();
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
  }

  void updateWeight(double weight) {
    state = state.copyWith(weightKg: weight);
    _recalculate();
  }

  void updateActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
    _recalculate();
  }

  void updateManualTarget(int? ml) {
    state = state.copyWith(manualTargetMl: ml);
  }

  void _recalculate() {
    final target = HydrationCalculator.calculateTarget(
      weightKg: state.weightKg,
      gender: state.gender,
      activityLevel: state.activityLevel,
    );
    state = state.copyWith(calculatedTargetMl: target.round());
  }

  Future<void> submitProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Generate UUID v4
      final userId = const Uuid().v4();

      // 2. Supabase Anonymous Auth (Required by AGENTS.md)
      await Supabase.instance.client.auth.signInAnonymously();

      // 3. Create UserProfile object
      final profile = UserProfile()
        ..userId = userId
        ..gender = state.gender
        ..age = state.age
        ..weightKg = state.weightKg
        ..activityLevel = state.activityLevel
        ..dailyTargetMl = state.manualTargetMl ?? state.calculatedTargetMl
        ..targetAccepted = state.manualTargetMl == null
        ..manualTargetMl = state.manualTargetMl
        ..notificationPermissionGranted = true // Captured during onboarding
        ..reminderSystemActive = true
        ..createdAt = DateTime.now()
        ..isSynced = false;

      // 4. Save to Repository
      await ref.read(profileRepositoryProvider).saveProfile(profile);

      // 5. Update Profile Status flag
      await ref.read(profileStatusProvider.notifier).setProfileCreated();
      
    } catch (e) {
      // Error handling as per constraints
      print('Profile submission error: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
