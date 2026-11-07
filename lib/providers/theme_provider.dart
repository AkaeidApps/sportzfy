import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` after `SharedPreferences.getInstance()` completes.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  );
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._preferences) : super(_read(_preferences));

  static const String _themeKey = 'sportzfy_theme_mode';

  final SharedPreferences _preferences;

  static ThemeMode _read(SharedPreferences preferences) {
    return preferences.getString(_themeKey) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  Future<void> setDark(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (state == mode) return;
    state = mode;
    await _preferences.setString(_themeKey, isDark ? 'dark' : 'light');
  }

  Future<void> toggle() => setDark(state != ThemeMode.dark);
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  return ThemeNotifier(ref.watch(sharedPreferencesProvider));
});
