import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'providers/iptv_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'services/cache_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  CacheService cacheService;
  try {
    await Hive.initFlutter();
    cacheService = await CacheService.open();
  } catch (error, stackTrace) {
    // The app remains fully usable without cache; it just re-downloads data.
    debugPrint('Hive initialisation failed: $error\n$stackTrace');
    cacheService = CacheService.disabled();
  }

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        cacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: const SportzfyApp(),
    ),
  );
}

class SportzfyApp extends ConsumerWidget {
  const SportzfyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Sportzfy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      themeAnimationCurve: Curves.easeOut,
      routerConfig: router,
      locale: Locale(language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
