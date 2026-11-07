import 'package:flutter_test/flutter_test.dart';
import 'package:sportzfy/l10n/app_language.dart';
import 'package:sportzfy/l10n/app_localizations.dart';
import 'package:sportzfy/models/channel_model.dart';
import 'package:sportzfy/screens/player_screen.dart';
import 'package:sportzfy/services/fallback_streams.dart';

void main() {
  const l10n = AppLocalizations(AppLanguage.english);

  group('Player fallback', () {
    test('tries every real mirror before the backup videos', () {
      const channel = Channel(
        id: 'tsports.bd',
        name: 'T Sports',
        logo: '',
        streamUrl: 'https://example.com/primary.m3u8',
        category: 'sports',
        userAgent: 'TestAgent',
        referrer: 'https://example.com',
        streams: <String>[
          'https://example.com/primary.m3u8',
          'https://example.com/backup.m3u8',
        ],
        streamHeaders: <Map<String, String>>[
          <String, String>{
            'User-Agent': 'TestAgent',
            'Referer': 'https://example.com',
          },
          <String, String>{'Referer': 'https://example.com'},
        ],
      );

      final args = PlayerArgs.fromChannel(channel, l10n: l10n);

      expect(args.playbackUrls, <String>[
        'https://example.com/primary.m3u8',
        'https://example.com/backup.m3u8',
      ]);
      expect(args.allPlaybackUrls, <String>[
        'https://example.com/primary.m3u8',
        'https://example.com/backup.m3u8',
        ...FallbackStreams.urls,
      ]);
      expect(args.isFallbackSource(1), isFalse);
      expect(args.isFallbackSource(2), isTrue);
      expect(
        args.headersForSource(0),
        containsPair('User-Agent', 'TestAgent'),
      );
      expect(args.headersForSource(2), isEmpty);
    });

    test('plays a backup video even when the channel has no stream', () {
      const channel = Channel(
        id: 'offline.bd',
        name: 'Offline Sports',
        logo: '',
        streamUrl: '',
        category: 'sports',
      );

      final args = PlayerArgs.fromChannel(channel, l10n: l10n);

      expect(args.playbackUrls, isEmpty);
      expect(args.allPlaybackUrls, FallbackStreams.urls);
      expect(args.isFallbackSource(0), isTrue);
      expect(args.headersForSource(0), isEmpty);
    });

    test('backup list is de-duplicated', () {
      final args = PlayerArgs(
        title: 'Test',
        streamUrl: FallbackStreams.urls.first,
        fallbackUrls: FallbackStreams.urls,
      );

      expect(args.allPlaybackUrls, FallbackStreams.urls);
    });
  });
}
