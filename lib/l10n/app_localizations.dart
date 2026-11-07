import 'package:flutter/material.dart';

import '../utils/bangla_formatters.dart' as fmt;
import 'app_language.dart';

/// Hand-written English/Bangla copy for the whole application.
///
/// English is the default language. Widgets read strings through
/// `context.l10n`, which rebuilds automatically when the language changes.
class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  bool get isBangla => language.isBangla;

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations is not registered.');
    return localizations ?? const AppLocalizations(AppLanguage.english);
  }

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(String en, String bn) => isBangla ? bn : en;

  // ---------------------------------------------------------------------------
  // Brand & navigation
  // ---------------------------------------------------------------------------

  String get appName => 'Sportzfy';
  String get appTagline => _t('All sports, one place', 'সব খেলা, এক জায়গায়');
  String get home => _t('Home', 'হোম');
  String get channels => _t('Channels', 'চ্যানেল');
  String get schedule => _t('Schedule', 'সূচি');
  String get highlights => _t('Highlights', 'হাইলাইট');
  String get menu => _t('Menu', 'মেনু');

  // ---------------------------------------------------------------------------
  // Home
  // ---------------------------------------------------------------------------

  String get welcome => _t('Welcome', 'স্বাগতম');
  String get liveMatches => _t('Live Matches', 'সরাসরি খেলা');
  String get liveMatchesSubtitle => _t(
    'Every live game in one place',
    'আজকের সেরা সব ম্যাচ এক জায়গায়',
  );
  String get upcomingMatches => _t('Upcoming Matches', 'আসন্ন খেলা');
  String get upcomingMatchesSubtitle => _t(
    'Plan ahead and never miss kick-off',
    'আগামী ম্যাচের সূচি দেখে রাখুন',
  );
  String get sportsChannels => _t('Sports Channels', 'স্পোর্টস চ্যানেল');
  String get watchLive => _t('Watch Live', 'লাইভ দেখুন');
  String get remindMe => _t('Remind Me', 'মনে করান');
  String get reminderSet => _t(
    'Reminder saved for this match',
    'এই ম্যাচের জন্য রিমাইন্ডার সেভ হয়েছে',
  );
  String get viewAll => _t('View all', 'সব দেখুন');
  String get liveNow => _t('Live now', 'চলছে এখন');
  String get vs => _t('VS', 'বনাম');
  String get heroTitle => _t('Every game,\none app', 'সব খেলা,\nএক অ্যাপে');
  String get heroSubtitle =>
      _t('Live streaming & highlights', 'লাইভ স্ট্রিমিং ও হাইলাইটস');
  String get liveEmptyTitle => _t('No live matches right now', 'এখন কোনো লাইভ ম্যাচ নেই');
  String get liveEmptySubtitle => _t(
    'Browse the sports channels below or check the upcoming schedule.',
    'নিচের স্পোর্টস চ্যানেল দেখুন অথবা আসন্ন সূচি দেখে রাখুন।',
  );
  String get upcomingEmptyTitle =>
      _t('Nothing scheduled', 'কোনো আসন্ন ম্যাচ নেই');
  String get upcomingEmptySubtitle => _t(
    'New fixtures will appear here automatically.',
    'নতুন ম্যাচের সূচি এখানে দেখা যাবে।',
  );

  String liveCountLabel(int count) => _t(
    '${fmt.localizeDigits(count, language)} Live',
    '${fmt.toBanglaDigits(count)} লাইভ',
  );
  String loadedChannelCount(int count) => _t(
    '${fmt.localizeDigits(count, language)} sports channels loaded',
    '${fmt.toBanglaDigits(count)}টি স্পোর্টস চ্যানেল লোড হয়েছে',
  );
  String matchCount(int count) => _t(
    '${fmt.localizeDigits(count, language)} matches',
    '${fmt.toBanglaDigits(count)}টি ম্যাচ',
  );
  String startsIn(String countdown) =>
      _t('Starts in $countdown', '$countdown পরে শুরু');
  String minuteUnit(int minutes) => _t('$minutes min', '$minutes মিনিট');

  // ---------------------------------------------------------------------------
  // Category / channels
  // ---------------------------------------------------------------------------

  String get searchHint => _t('Search channels...', 'চ্যানেল খুঁজুন...');
  String get allSports => _t('All', 'সব');
  String get filterChannels => _t('Filter channels', 'চ্যানেল ফিল্টার');
  String get noChannelTitle =>
      _t('No channels found', 'কোনো চ্যানেল পাওয়া যায়নি');
  String get noChannelSubtitle => _t(
    'Try another name or a different sport.',
    'অন্য নাম বা ক্যাটাগরি দিয়ে খুঁজে দেখুন।',
  );
  String get clearFilters => _t('Clear filters', 'ফিল্টার মুছুন');
  String get liveSportsChannel =>
      _t('Live sports channel', 'লাইভ স্পোর্টস চ্যানেল');
  String get searchCleared => _t('Search cleared', 'সার্চ মুছে ফেলা হয়েছে');
  String get noChannelStream =>
      _t('No playable stream available', 'চালানোর মতো স্ট্রিম পাওয়া যায়নি');

  String channelCount(int count) => _t(
    '${fmt.localizeDigits(count, language)} channels',
    '${fmt.toBanglaDigits(count)}টি চ্যানেল',
  );

  String sportLabel(String id) {
    return switch (id) {
      'all' => allSports,
      'cricket' => _t('Cricket', 'ক্রিকেট'),
      'football' => _t('Football', 'ফুটবল'),
      'tennis' => _t('Tennis', 'টেনিস'),
      'golf' => _t('Golf', 'গলফ'),
      'racing' => _t('Racing', 'রেসিং'),
      'fighting' => _t('Fighting', 'ফাইটিং'),
      _ => _t('Other', 'অন্যান্য'),
    };
  }

  // ---------------------------------------------------------------------------
  // Schedule / highlights
  // ---------------------------------------------------------------------------

  String get scheduleSubtitle => _t(
    'Full fixture list for the next few days',
    'আগামী দিনের পূর্ণ ম্যাচ সূচি',
  );
  String get noUpcomingTitle =>
      _t('No upcoming matches', 'কোনো আসন্ন ম্যাচ নেই');
  String get noUpcomingSubtitle => _t(
    'Check back later for new fixtures.',
    'নতুন সূচির জন্য পরে আবার দেখুন।',
  );
  String get recent => _t('Recent', 'সাম্প্রতিক');
  String get matchHighlights => _t('Match Highlights', 'ম্যাচ হাইলাইট');
  String get highlightsSubtitle => _t(
    'Watch the best moments from missed matches',
    'মিস করা ম্যাচের সেরা মুহূর্তগুলো দেখুন',
  );
  String get highlight => _t('Highlight', 'হাইলাইট');
  String get highlightsEmptyTitle =>
      _t('No highlights yet', 'এখনো কোনো হাইলাইট নেই');
  String get highlightsEmptySubtitle => _t(
    'Highlights of finished matches will appear here.',
    'শেষ হওয়া ম্যাচের হাইলাইট এখানে দেখা যাবে।',
  );

  // ---------------------------------------------------------------------------
  // States & errors
  // ---------------------------------------------------------------------------

  String get loadingChannels =>
      _t('Loading sports channels...', 'স্পোর্টস চ্যানেল লোড হচ্ছে...');
  String get loadingChannelsHint => _t(
    'The first load can take a few seconds',
    'প্রথমবার লোড হতে কিছুটা সময় লাগতে পারে',
  );
  String get loading => _t('Loading...', 'লোড হচ্ছে...');
  String get noInternet => _t('No internet connection', 'ইন্টারনেট সংযোগ নেই');
  String get noInternetHint => _t(
    'Check your connection and try again.',
    'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।',
  );
  String get serverError => _t('Server error', 'সার্ভারে সমস্যা হয়েছে');
  String get serverErrorHint =>
      _t('Please try again in a moment.', 'কিছুক্ষণ পর আবার চেষ্টা করুন।');
  String get parseError => _t('Could not read data', 'ডেটা পড়া যায়নি');
  String get unknownError => _t('Something went wrong', 'কিছু একটা সমস্যা হয়েছে');
  String get unknownErrorHint => _t('Please try again.', 'আবার চেষ্টা করুন।');
  String get retry => _t('Try again', 'আবার চেষ্টা করুন');
  String get cachedBanner => _t(
    'Offline — showing your saved channel list',
    'ইন্টারনেট সংযোগ নেই — সেভ করা তালিকা দেখানো হচ্ছে',
  );
  String get offlineHint => _t('Saved offline data', 'অফলাইনে সেভ করা ডেটা');
  String get pageNotFound => _t('Page not found', 'পেজটি পাওয়া যায়নি');
  String get pageNotFoundBody => _t(
    'This address could not be found.',
    'এই ঠিকানাটি খুঁজে পাওয়া যায়নি।',
  );
  String get goHome => _t('Go home', 'হোমে যান');
  String get removed => _t('Removed', 'মুছে ফেলা হয়েছে');
  String get channelUnavailable => _t(
    'This channel has no working stream right now.',
    'এই চ্যানেলের কোনো চালু স্ট্রিম এখন পাওয়া যাচ্ছে না।',
  );
  String get channelUnavailableHint => _t(
    'Try another channel or refresh the channel list.',
    'অন্য চ্যানেল চেষ্টা করুন অথবা তালিকা রিফ্রেশ করুন।',
  );

  // ---------------------------------------------------------------------------
  // Player
  // ---------------------------------------------------------------------------

  String get streamLoading => _t('Loading stream...', 'স্ট্রিম লোড হচ্ছে...');
  String get backupStream => _t('Backup', 'ব্যাকআপ');
  String get loadingBackup => _t(
    'Channel is offline — loading a backup video...',
    'চ্যানেল বন্ধ আছে — ব্যাকআপ ভিডিও লোড হচ্ছে...',
  );
  String get streamError => _t('Unable to play this stream', 'স্ট্রিমটি চালানো যাচ্ছে না');
  String get streamErrorHint => _t(
    'Check your internet connection or try another source.',
    'ইন্টারনেট সংযোগ বা স্ট্রিম লিংকটি পরীক্ষা করুন।',
  );
  String get emptyStream =>
      _t('No stream link found for this match.', 'এই খেলার স্ট্রিম লিংক পাওয়া যায়নি।');
  String get back => _t('Go back', 'ফিরে যান');
  String get live => _t('LIVE', 'লাইভ');
  String get upcoming => _t('Upcoming', 'আসন্ন');
  String get mute => _t('Mute', 'মিউট করুন');
  String get unmute => _t('Unmute', 'আনমিউট করুন');
  String get play => _t('Play', 'চালান');
  String get pause => _t('Pause', 'থামান');
  String sourceOf(int current, int total) =>
      _t('Source $current/$total', 'সোর্স $current/$total');
  String tryingSource(int current, int total) => _t(
    'Trying source $current of $total...',
    'সোর্স $current/$total চেষ্টা করা হচ্ছে...',
  );
  String get switchSource => _t('Switch source', 'সোর্স পরিবর্তন করুন');

  // ---------------------------------------------------------------------------
  // Drawer / about
  // ---------------------------------------------------------------------------

  String get theme => _t('Theme', 'থিম');
  String get darkMode => _t('Dark mode', 'ডার্ক মোড');
  String get lightMode => _t('Light mode', 'লাইট মোড');
  String get languageLabel => _t('Language', 'ভাষা');
  String get english => 'English';
  String get bangla => 'বাংলা';
  String get refreshData => _t('Refresh data', 'ডেটা রিফ্রেশ করুন');
  String get refreshing => _t('Refreshing data...', 'ডেটা রিফ্রেশ হচ্ছে...');
  String get about => _t('About', 'অ্যাপ সম্পর্কে');
  String get aboutTitle => _t('About Sportzfy', 'স্পোর্টজফাই সম্পর্কে');
  String get aboutBody => _t(
    'An educational Flutter project built for learning. Channel and stream '
        'data come from the open-source iptv-org API. No content is owned by '
        'this app.',
    'এটি শুধুমাত্র শিক্ষামূলক উদ্দেশ্যে তৈরি একটি ফ্লাটার প্রজেক্ট। '
        'চ্যানেল ও স্ট্রিমের তথ্য iptv-org-এর ওপেন সোর্স API থেকে নেওয়া হয়। '
        'কোনো কনটেন্ট এই অ্যাপের মালিকানাধীন নয়।',
  );
  String get educationalOnly =>
      _t('For educational use only', 'শুধুমাত্র শিক্ষার উদ্দেশ্যে');
  String get dataSource => _t('Data source: iptv-org', 'ডেটা সোর্স: iptv-org');
  String get version => _t('Version 1.0.0', 'সংস্করণ ১.০.০');
  String get close => _t('Close', 'বন্ধ করুন');

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  String digits(Object? value) => fmt.localizeDigits(value, language);
  String formatDate(DateTime date) => fmt.formatDate(date, language);
  String formatTime(DateTime date) => fmt.formatTime(date, language);
  String formatMatchDateTime(DateTime date, {DateTime? now}) =>
      fmt.formatMatchDateTime(date, now: now, language: language);
  String formatRelativeDay(DateTime date, {DateTime? now}) =>
      fmt.formatRelativeDay(date, now: now, language: language);
  String formatRelativeTime(DateTime date, {DateTime? now}) =>
      fmt.formatRelativeTime(date, now: now, language: language);
  String formatDuration(Duration duration) =>
      fmt.formatVideoDuration(duration, language: language);
  String formatCountdown(Duration duration) =>
      fmt.formatCountdown(duration, language: language);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'bn';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(AppLanguage.fromCode(locale.languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
