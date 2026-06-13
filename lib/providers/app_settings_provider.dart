import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_provider.dart';

class AppSettingsState {
  final bool lightweightMode;

  const AppSettingsState({this.lightweightMode = false});

  AppSettingsState copyWith({bool? lightweightMode}) {
    return AppSettingsState(
      lightweightMode: lightweightMode ?? this.lightweightMode,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  static const _lightweightModeKey = 'lightweightMode';

  @override
  AppSettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettingsState(
      lightweightMode: prefs.getBool(_lightweightModeKey) ?? false,
    );
  }

  Future<void> setLightweightMode(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_lightweightModeKey, value);
    state = state.copyWith(lightweightMode: value);
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_lightweightModeKey);
    state = const AppSettingsState();
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(() {
      return AppSettingsNotifier();
    });
