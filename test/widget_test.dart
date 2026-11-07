import 'package:flutter_test/flutter_test.dart';
import 'package:sportzfy/l10n/app_language.dart';
import 'package:sportzfy/l10n/app_localizations.dart';
import 'package:sportzfy/l10n/localized_text.dart';
import 'package:sportzfy/models/channel_model.dart';
import 'package:sportzfy/models/match_model.dart';
import 'package:sportzfy/repository/iptv_repository.dart';
import 'package:sportzfy/utils/bangla_formatters.dart';

void main() {
  group('Formatters', () {
    test('converts ASCII digits to Bangla digits', () {
      expect(toBanglaDigits(1234567890), '১২৩৪৫৬৭৮৯০');
      expect(toBanglaDigits('2026'), '২০২৬');
      expect(toBanglaDigits('ম্যাচ ৫'), 'ম্যাচ ৫');
    });

    test('localizes digits for the selected language', () {
      expect(localizeDigits(2026, AppLanguage.english), '2026');
      expect(localizeDigits(2026, AppLanguage.bangla), '২০২৬');
    });

    test('formats video durations in English and Bangla', () {
      const duration = Duration(minutes: 2, seconds: 7);
      expect(formatVideoDuration(duration), '02:07');
      expect(
        formatVideoDuration(duration, language: AppLanguage.bangla),
        '০২:০৭',
      );
      expect(
        formatVideoDuration(
          const Duration(hours: 1, minutes: 3, seconds: 9),
          language: AppLanguage.bangla,
        ),
        '১:০৩:০৯',
      );
    });

    test('formats relative days in English and Bangla', () {
      final now = DateTime(2026, 11, 7, 12);
      expect(formatRelativeDay(now, now: now), 'Today');
      expect(
        formatRelativeDay(now, now: now, language: AppLanguage.bangla),
        'আজ',
      );
      expect(
        formatRelativeDay(
          now.subtract(const Duration(days: 1)),
          now: now,
          language: AppLanguage.bangla,
        ),
        'গতকাল',
      );
      expect(
        formatRelativeDay(
          now.add(const Duration(days: 1)),
          now: now,
          language: AppLanguage.bangla,
        ),
        'আগামীকাল',
      );
    });

    test('formats countdowns in English and Bangla', () {
      const remaining = Duration(hours: 2, minutes: 30);
      expect(formatCountdown(remaining), '2h 30m');
      expect(
        formatCountdown(remaining, language: AppLanguage.bangla),
        '২ ঘণ্টা ৩০ মিনিট',
      );
    });

    test('creates a flag emoji from an ISO country code', () {
      expect(countryFlag('bd'), '🇧🇩');
      expect(countryFlag('in'), '🇮🇳');
      expect(countryFlag(null), '');
      expect(countryFlag('invalid'), '');
    });
  });

  group('Localization', () {
    const english = AppLocalizations(AppLanguage.english);
    const bangla = AppLocalizations(AppLanguage.bangla);

    test('defaults to English copy', () {
      expect(english.language, AppLanguage.english);
      expect(english.liveMatches, 'Live Matches');
      expect(english.schedule, 'Schedule');
      expect(english.watchLive, 'Watch Live');
    });

    test('exposes Bangla copy for the same keys', () {
      expect(bangla.language, AppLanguage.bangla);
      expect(bangla.liveMatches, 'সরাসরি খেলা');
      expect(bangla.schedule, 'সূচি');
      expect(bangla.watchLive, 'লাইভ দেখুন');
    });

    test('localizes canonical sport ids', () {
      expect(english.sportLabel(SportGroups.cricket), 'Cricket');
      expect(bangla.sportLabel(SportGroups.cricket), 'ক্রিকেট');
      expect(bangla.sportLabel(SportGroups.other), 'অন্যান্য');
    });

    test('localizes numbers and dates', () {
      expect(english.digits(2026), '2026');
      expect(bangla.digits(2026), '২০২৬');
      expect(
        english.formatDate(DateTime(2026, 11, 7)),
        'Saturday, 7 November 2026',
      );
      expect(
        bangla.formatDate(DateTime(2026, 11, 7)),
        'শনিবার, ৭ নভেম্বর ২০২৬',
      );
    });
  });

  group('Channel model', () {
    test('serialises and deserialises without losing data', () {
      const channel = Channel(
        id: 'tsports.bd',
        name: 'T Sports',
        logo: 'https://example.com/logo.png',
        streamUrl: 'https://example.com/stream.m3u8',
        category: 'sports',
        country: 'BD',
        quality: '1080p',
        userAgent: 'TestAgent',
        referrer: 'https://example.com',
        streams: <String>[
          'https://example.com/stream.m3u8',
          'https://example.com/backup.m3u8',
        ],
      );

      final restored = Channel.fromJson(channel.toJson());

      expect(restored.id, channel.id);
      expect(restored.name, channel.name);
      expect(restored.logo, channel.logo);
      expect(restored.streamUrl, channel.streamUrl);
      expect(restored.category, channel.category);
      expect(restored.country, channel.country);
      expect(restored.quality, channel.quality);
      expect(restored.userAgent, channel.userAgent);
      expect(restored.referrer, channel.referrer);
      expect(restored.streams, channel.streams);
      expect(restored.playbackUrls, channel.playbackUrls);
    });

    test('de-duplicates and orders fallback playback URLs', () {
      const channel = Channel(
        id: 'tsports.bd',
        name: 'T Sports',
        logo: '',
        streamUrl: 'https://example.com/primary.m3u8',
        category: 'sports',
        streams: <String>[
          'https://example.com/primary.m3u8',
          'https://example.com/backup.m3u8',
          '  ',
          'https://example.com/third.m3u8',
        ],
      );

      expect(channel.playbackUrls, <String>[
        'https://example.com/primary.m3u8',
        'https://example.com/backup.m3u8',
        'https://example.com/third.m3u8',
      ]);
      expect(channel.hasStream, isTrue);
    });

    test('infers canonical sport groups from channel names', () {
      Channel channel(String name) => Channel(
        id: name,
        name: name,
        logo: '',
        streamUrl: 'https://example.com/live.m3u8',
        category: 'sports',
      );

      expect(channel('Star Sports 1').sportGroup, SportGroups.cricket);
      expect(channel('Sky Sports Football').sportGroup, SportGroups.football);
      expect(channel('Wimbledon Tennis').sportGroup, SportGroups.tennis);
      expect(channel('PGA Golf').sportGroup, SportGroups.golf);
      expect(channel('Formula 1 Racing').sportGroup, SportGroups.racing);
      expect(channel('UFC Fight Pass').sportGroup, SportGroups.fighting);
      expect(channel('Some Random Sports').sportGroup, SportGroups.other);
    });
  });

  group('Match model', () {
    test('resolves localized text and exposes playable sources', () {
      final match = MatchModel(
        id: 'ban-vs-pak',
        teamA: const LocalizedText(en: 'Bangladesh', bn: 'বাংলাদেশ'),
        teamB: const LocalizedText(en: 'Pakistan', bn: 'পাকিস্তান'),
        teamALogo: '',
        teamBLogo: '',
        league: const LocalizedText(en: 'Asia Cup', bn: 'এশিয়া কাপ'),
        startTime: DateTime(2026, 11, 7, 19),
        isLive: true,
        streamUrls: const <String>['', 'https://example.com/live.m3u8'],
      );

      expect(match.teamAFor(AppLanguage.english), 'Bangladesh');
      expect(match.teamAFor(AppLanguage.bangla), 'বাংলাদেশ');
      expect(match.leagueFor(AppLanguage.bangla), 'এশিয়া কাপ');
      expect(match.canPlay, isTrue);
    });
  });

  group('Catalog merge', () {
    const sportsChannel = <String, dynamic>{
      'id': 'sports.bd',
      'name': 'T Sports',
      'country': 'BD',
      'categories': <String>['sports'],
      'closed': null,
      'is_nsfw': false,
    };
    const newsChannel = <String, dynamic>{
      'id': 'news.bd',
      'name': 'News 24',
      'country': 'BD',
      'categories': <String>['news'],
      'closed': null,
      'is_nsfw': false,
    };
    const closedSportsChannel = <String, dynamic>{
      'id': 'closed.bd',
      'name': 'Old Sports',
      'country': 'BD',
      'categories': <String>['sports'],
      'closed': '2024-01-01',
      'is_nsfw': false,
    };
    const streamlessSportsChannel = <String, dynamic>{
      'id': 'streamless.bd',
      'name': 'Offline Sports',
      'country': 'BD',
      'categories': <String>['sports'],
      'closed': null,
      'is_nsfw': false,
    };

    test('keeps sports channels and adds fallback play URLs for streamless channels', () {
      final merged = IptvRepository.mergeCatalog(
        channelsJson: <dynamic>[
          sportsChannel,
          newsChannel,
          closedSportsChannel,
          streamlessSportsChannel,
        ],
        streamsJson: <dynamic>[
          <String, dynamic>{
            'channel': 'sports.bd',
            'feed': null,
            'url': 'https://example.com/tsports.m3u8',
            'quality': '1080p',
            'labels': <String>[],
            'user_agent': null,
            'referrer': null,
          },
        ],
        logosJson: <dynamic>[
          <String, dynamic>{
            'channel': 'sports.bd',
            'feed': null,
            'in_use': true,
            'width': 512,
            'height': 512,
            'format': 'SVG',
            'url': 'https://example.com/logo.svg',
          },
          <String, dynamic>{
            'channel': 'sports.bd',
            'feed': null,
            'in_use': true,
            'width': 256,
            'height': 256,
            'format': 'PNG',
            'url': 'https://example.com/logo.png',
          },
        ],
        feedsJson: <dynamic>[
          <String, dynamic>{
            'channel': 'sports.bd',
            'id': 'SD',
            'name': 'SD',
            'is_main': true,
          },
        ],
      );

      expect(merged, hasLength(2));
      final sports = merged.firstWhere((c) => c.id == 'sports.bd');
      expect(sports.name, 'T Sports');
      expect(sports.category, 'sports');
      expect(sports.country, 'BD');
      expect(sports.streamUrl, 'https://example.com/tsports.m3u8');
      expect(sports.logo, 'https://example.com/logo.png');
      expect(sports.quality, '1080p');
      expect(sports.playbackUrls.first, 'https://example.com/tsports.m3u8');
      expect(sports.playbackUrls.length, greaterThan(1));

      final streamless = merged.firstWhere((c) => c.id == 'streamless.bd');
      expect(streamless.name, 'Offline Sports');
      expect(streamless.playbackUrls, isNotEmpty);
    });

    test('prefers an HTTPS main-feed stream over higher quality HTTP and includes fallbacks', () {
      final merged = IptvRepository.mergeCatalog(
        channelsJson: <dynamic>[sportsChannel],
        streamsJson: <dynamic>[
          <String, dynamic>{
            'channel': 'sports.bd',
            'feed': null,
            'url': 'http://example.com/1080.m3u8',
            'quality': '1080p',
            'labels': <String>[],
          },
          <String, dynamic>{
            'channel': 'sports.bd',
            'feed': 'SD',
            'url': 'https://example.com/720.m3u8',
            'quality': '720p',
            'labels': <String>[],
          },
        ],
        logosJson: const <dynamic>[],
        feedsJson: <dynamic>[
          <String, dynamic>{
            'channel': 'sports.bd',
            'id': 'SD',
            'name': 'SD',
            'is_main': true,
          },
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.streamUrl, 'https://example.com/720.m3u8');
      expect(merged.single.logo, isEmpty);
      expect(merged.single.playbackUrls.sublist(0, 2), <String>[
        'https://example.com/720.m3u8',
        'http://example.com/1080.m3u8',
      ]);
    });

    test('keeps channels whose logo is missing and ignores bad data', () {
      final merged = IptvRepository.mergeCatalog(
        channelsJson: <dynamic>[
          sportsChannel,
          <String, dynamic>{'id': '', 'name': 'Broken'},
          'not-a-map',
        ],
        streamsJson: <dynamic>[
          <String, dynamic>{
            'channel': 'sports.bd',
            'url': 'https://example.com/live.m3u8',
            'quality': '720p',
            'labels': <String>[],
          },
          <String, dynamic>{
            'channel': null,
            'url': 'https://example.com/unattached.m3u8',
          },
        ],
        logosJson: const <dynamic>[],
        feedsJson: const <dynamic>[],
      );

      expect(merged, hasLength(1));
      expect(merged.single.name, 'T Sports');
      expect(merged.single.logo, isEmpty);
    });
  });
}
