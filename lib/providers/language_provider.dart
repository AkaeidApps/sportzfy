import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import 'theme_provider.dart';

/// Persists the interface language. English is the default.
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier(this._preferences)
    : super(
        AppLanguage.fromCode(_preferences.getString(_languageKey)),
      );

  static const String _languageKey = 'sportzfy_language';

  final SharedPreferences _preferences;

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    await _preferences.setString(_languageKey, language.code);
  }

  Future<void> toggle() => setLanguage(
    state == AppLanguage.english ? AppLanguage.bangla : AppLanguage.english,
  );
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((
  ref,
) {
  return LanguageNotifier(ref.watch(sharedPreferencesProvider));
});
