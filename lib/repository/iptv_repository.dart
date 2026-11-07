import '../l10n/localized_text.dart';
import '../models/channel_model.dart';
import '../models/feed_model.dart';
import '../models/highlight_model.dart';
import '../models/logo_model.dart';
import '../models/match_model.dart';
import '../models/stream_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/fallback_streams.dart';

/// Result of loading the channel catalog.
class CatalogResult {
  const CatalogResult({
    required this.channels,
    required this.savedAt,
    required this.fromCache,
    required this.networkFailed,
  });

  final List<Channel> channels;
  final DateTime savedAt;
  final bool fromCache;

  /// True when a network request failed and stale cache was used instead.
  final bool networkFailed;
}

/// Data layer for channels, matches and highlights.
class IptvRepository {
  factory IptvRepository({
    required ApiService api,
    required CacheService cache,
  }) {
    return IptvRepository._(api, cache);
  }

  IptvRepository._(this._api, this._cache);

  final ApiService _api;
  final CacheService _cache;
  bool _backgroundRefreshStarted = false;

  /// Demo media used by the curated match/highlight feed. In a production app
  /// these URLs would come from a live fixtures API.
  static const String _sampleVideoOne =
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4';
  static const String _sampleVideoTwo =
      'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4';
  static const String _sampleVideoThree =
      'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4';
  static const String _sampleVideoFour =
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4';
  static const String _sampleVideoFive =
      'https://media.w3.org/2010/05/sintel/trailer.mp4';

  /// Loads the merged catalog using cache-first, network-fallback semantics.
  Future<CatalogResult> loadCatalog({bool forceRefresh = false}) async {
    final cached = await _cache.readCatalog();

    // Always serve an existing catalog immediately. A stale list is still
    // useful while the larger upstream JSON files refresh in the background.
    if (!forceRefresh && cached != null && cached.channels.isNotEmpty) {
      if (cached.isExpired && !_backgroundRefreshStarted) {
        _backgroundRefreshStarted = true;
        // Refresh after returning the cached data. Errors are intentionally
        // swallowed here because the visible catalog is already usable.
        // Use unawaited to avoid blocking the cached response.
        Future<void>.delayed(const Duration(milliseconds: 100), () async {
          try {
            final raw = await _api.fetchCatalog();
            final refreshed = mergeCatalog(
              channelsJson: raw.channels,
              streamsJson: raw.streams,
              logosJson: raw.logos,
              feedsJson: raw.feeds,
            );
            if (refreshed.isNotEmpty) await _cache.writeCatalog(refreshed);
          } catch (_) {
            // Keep the last cached catalog available offline.
          }
        });
      }
      return CatalogResult(
        channels: cached.channels,
        savedAt: cached.savedAt,
        fromCache: true,
        networkFailed: false,
      );
    }

    try {
      final raw = await _api.fetchCatalog();
      final merged = mergeCatalog(
        channelsJson: raw.channels,
        streamsJson: raw.streams,
        logosJson: raw.logos,
        feedsJson: raw.feeds,
      );

      if (merged.isNotEmpty) {
        await _cache.writeCatalog(merged);
      }

      return CatalogResult(
        channels: merged,
        savedAt: DateTime.now(),
        fromCache: false,
        networkFailed: false,
      );
    } catch (_) {
      // If the API is unreachable, stale data is still better than an empty
      // screen. The UI surfaces a "no internet" banner in this case.
      if (cached != null && cached.channels.isNotEmpty) {
        return CatalogResult(
          channels: cached.channels,
          savedAt: cached.savedAt,
          fromCache: true,
          networkFailed: true,
        );
      }
      rethrow;
    }
  }

  /// Joins the four public data sets and returns only usable sports channels.
  ///
  /// Exposed as a static method so the merge logic can be unit tested without
  /// any network or Hive dependencies.
  static List<Channel> mergeCatalog({
    required List<dynamic> channelsJson,
    required List<dynamic> streamsJson,
    required List<dynamic> logosJson,
    required List<dynamic> feedsJson,
  }) {
    final streamsByChannel = _groupStreams(streamsJson);
    final logosByChannel = _groupLogos(logosJson);
    final mainFeedsByChannel = _mapMainFeeds(feedsJson);
    final merged = <Channel>[];

    for (final item in channelsJson) {
      if (item is! Map) continue;
      final json = Map<String, dynamic>.from(item);

      final id = (json['id'] as String?)?.trim() ?? '';
      final name = (json['name'] as String?)?.trim() ?? '';
      if (id.isEmpty || name.isEmpty) continue;

      final rawCategories = json['categories'];
      final categories = rawCategories is List
          ? rawCategories
                .whereType<String>()
                .map((category) => category.toLowerCase())
                .toSet()
          : const <String>{};
      if (!categories.contains('sports')) continue;

      // Skip closed, replaced and adult channels.
      if (json['closed'] != null) continue;
      if (json['is_nsfw'] == true) continue;

      final streams = streamsByChannel[id];
      final mainFeeds = mainFeedsByChannel[id] ?? const <String>{};
      final ranked = streams != null ? _rankStreams(streams, mainFeeds) : const <StreamModel>[];

      final logo = _pickLogo(logosByChannel[id]);
      final country = (json['country'] as String?)?.trim();

      final rankedUrls = _playbackUrls(ranked);
      final streamUrl = rankedUrls.isNotEmpty ? rankedUrls.first : FallbackStreams.urls.first;
      final allStreams = <String>[
        ...rankedUrls,
        ...FallbackStreams.urls,
      ];

      merged.add(
        Channel(
          id: id,
          name: name,
          logo: logo,
          streamUrl: streamUrl,
          category: 'sports',
          country: country?.isEmpty ?? true ? null : country,
          quality: ranked.isNotEmpty ? ranked.first.quality : 'HD',
          userAgent: ranked.isNotEmpty ? ranked.first.userAgent : null,
          referrer: ranked.isNotEmpty ? ranked.first.referrer : null,
          streams: allStreams,
          streamHeaders: _streamHeaders(ranked),
        ),
      );
    }

    merged.sort(_compareChannels);
    return merged;
  }

  static Map<String, List<StreamModel>> _groupStreams(List<dynamic> raw) {
    final grouped = <String, List<StreamModel>>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final stream = StreamModel.fromJson(Map<String, dynamic>.from(item));
      final channel = stream.channel;
      if (channel == null || channel.isEmpty || !stream.hasUrl) continue;
      grouped.putIfAbsent(channel, () => <StreamModel>[]).add(stream);
    }
    return grouped;
  }

  static Map<String, List<LogoModel>> _groupLogos(List<dynamic> raw) {
    final grouped = <String, List<LogoModel>>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final logo = LogoModel.fromJson(Map<String, dynamic>.from(item));
      final channel = logo.channel;
      if (channel == null || channel.isEmpty || !logo.hasUrl) continue;
      grouped.putIfAbsent(channel, () => <LogoModel>[]).add(logo);
    }
    return grouped;
  }

  static Map<String, Set<String>> _mapMainFeeds(List<dynamic> raw) {
    final grouped = <String, Set<String>>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final feed = FeedModel.fromJson(Map<String, dynamic>.from(item));
      final channel = feed.channel;
      if (channel == null ||
          channel.isEmpty ||
          !feed.isMain ||
          feed.id.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(channel, () => <String>{}).add(feed.id);
    }
    return grouped;
  }

  /// Prefers HTTPS, then the main feed, then higher resolution.
  ///
  /// Returns every playable source so the player can fall back automatically
  /// when a provider is offline.
  static List<StreamModel> _rankStreams(
    List<StreamModel> streams,
    Set<String> mainFeeds,
  ) {
    final usable = streams
        .where((stream) => stream.hasUrl && _isPlayableUrl(stream.url))
        .toList(growable: false);
    if (usable.isEmpty) return const <StreamModel>[];

    int score(StreamModel stream) {
      var value = stream.qualityValue;
      if (stream.isHttps) value += 2000;
      if (stream.feed == null || mainFeeds.contains(stream.feed)) {
        value += 500;
      }
      if (stream.isAlwaysOn) value += 100;
      return value;
    }

    final ranked = usable.toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    return ranked;
  }

  static List<String> _playbackUrls(List<StreamModel> ranked) {
    final urls = <String>[];
    for (final stream in ranked) {
      final url = stream.url.trim();
      if (url.isEmpty || urls.contains(url)) continue;
      urls.add(url);
      if (urls.length >= 6) break;
    }
    return urls;
  }

  static List<Map<String, String>> _streamHeaders(List<StreamModel> ranked) {
    final headers = <Map<String, String>>[];
    final seen = <String>{};
    for (final stream in ranked) {
      final url = stream.url.trim();
      if (url.isEmpty || !seen.add(url)) continue;
      headers.add(<String, String>{
        if ((stream.userAgent ?? '').trim().isNotEmpty)
          'User-Agent': stream.userAgent!.trim(),
        if ((stream.referrer ?? '').trim().isNotEmpty)
          'Referer': stream.referrer!.trim(),
      });
      if (headers.length >= 6) break;
    }
    return headers;
  }

  static bool _isPlayableUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Picks an in-use raster logo with the largest resolution.
  ///
  /// SVG logos are skipped because `CachedNetworkImage` cannot render them;
  /// those channels simply use the local fallback tile.
  static String _pickLogo(List<LogoModel>? logos) {
    if (logos == null || logos.isEmpty) return '';

    final usable = logos
        .where((logo) => logo.hasUrl && !logo.isSvg)
        .toList(growable: false);
    if (usable.isEmpty) return '';

    final sorted = usable.toList()
      ..sort((a, b) {
        if (a.feed == null && b.feed != null) return -1;
        if (b.feed == null && a.feed != null) return 1;
        if (a.inUse != b.inUse) return a.inUse ? -1 : 1;
        final byWidth = b.width.compareTo(a.width);
        if (byWidth != 0) return byWidth;
        return a.url.length.compareTo(b.url.length);
      });

    return sorted.first.url;
  }

  static int _compareChannels(Channel a, Channel b) {
    const priority = <String, int>{'BD': 0, 'IN': 1, 'PK': 2, 'GB': 3, 'US': 4};

    final aPriority = priority[a.country?.toUpperCase()] ?? 5;
    final bPriority = priority[b.country?.toUpperCase()] ?? 5;
    if (aPriority != bPriority) return aPriority.compareTo(bPriority);

    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  }

  /// Curated fixtures linked to real channels from the loaded catalog.
  ///
  /// Live matches open the linked channel's stream, so the play button behaves
  /// exactly like tapping a channel card. Upcoming fixtures keep their channel
  /// and schedule data for the reminder UI.
  List<MatchModel> buildMatches(List<Channel> channels) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return <MatchModel>[
      _fixture(
        id: 'ban-vs-pak',
        teamAEn: 'Bangladesh',
        teamABn: 'বাংলাদেশ',
        teamBEn: 'Pakistan',
        teamBBn: 'পাকিস্তান',
        teamALogo: 'https://flagcdn.com/w320/bd.png',
        teamBLogo: 'https://flagcdn.com/w320/pk.png',
        leagueEn: 'ICC Champions Trophy',
        leagueBn: 'আইসিসি চ্যাম্পিয়ন্স ট্রফি',
        startTime: now.subtract(const Duration(minutes: 40)),
        venueEn: 'Sher-e-Bangla National Stadium, Dhaka',
        venueBn: 'শের-ই-বাংলা জাতীয় ক্রিকেট স্টেডিয়াম, ঢাকা',
        isLive: true,
        sport: SportGroups.cricket,
        channels: channels,
        hints: const <String>['t sports', 'star sports 1', 'sports18'],
      ),
      _fixture(
        id: 'rma-vs-bar',
        teamAEn: 'Real Madrid',
        teamABn: 'রিয়াল মাদ্রিদ',
        teamBEn: 'Barcelona',
        teamBBn: 'বার্সেলোনা',
        teamALogo: 'https://a.espncdn.com/i/teamlogos/soccer/500/86.png',
        teamBLogo: 'https://a.espncdn.com/i/teamlogos/soccer/500/83.png',
        leagueEn: 'UEFA Champions League',
        leagueBn: 'উয়েফা চ্যাম্পিয়ন্স লিগ',
        startTime: now.subtract(const Duration(minutes: 15)),
        venueEn: 'Santiago Bernabéu',
        venueBn: 'সান্তিয়াগো বার্নাব্যু',
        isLive: true,
        sport: SportGroups.football,
        channels: channels,
        hints: const <String>[
          'sony sports 2',
          'bein sports',
          'sky sports football',
        ],
      ),
      _fixture(
        id: 'ind-vs-aus',
        teamAEn: 'India',
        teamABn: 'ভারত',
        teamBEn: 'Australia',
        teamBBn: 'অস্ট্রেলিয়া',
        teamALogo: 'https://flagcdn.com/w320/in.png',
        teamBLogo: 'https://flagcdn.com/w320/au.png',
        leagueEn: 'ICC Champions Trophy',
        leagueBn: 'আইসিসি চ্যাম্পিয়ন্স ট্রফি',
        startTime: now.add(const Duration(hours: 2, minutes: 30)),
        venueEn: 'Melbourne Cricket Ground',
        venueBn: 'মেলবোর্ন ক্রিকেট গ্রাউন্ড',
        sport: SportGroups.cricket,
        channels: channels,
        hints: const <String>['star sports 1', 'sports18', 'ten 1'],
      ),
      _fixture(
        id: 'mci-vs-liv',
        teamAEn: 'Manchester City',
        teamABn: 'ম্যানচেস্টার সিটি',
        teamBEn: 'Liverpool',
        teamBBn: 'লিভারপুল',
        teamALogo: 'https://a.espncdn.com/i/teamlogos/soccer/500/382.png',
        teamBLogo: 'https://a.espncdn.com/i/teamlogos/soccer/500/364.png',
        leagueEn: 'Premier League',
        leagueBn: 'প্রিমিয়ার লিগ',
        startTime: now.add(const Duration(hours: 4)),
        venueEn: 'Etihad Stadium',
        venueBn: 'এতিহাদ স্টেডিয়াম',
        sport: SportGroups.football,
        channels: channels,
        hints: const <String>[
          'star sports select 1',
          'sky sports premier league',
          'bein sports 1',
        ],
      ),
      _fixture(
        id: 'bra-vs-arg',
        teamAEn: 'Brazil',
        teamABn: 'ব্রাজিল',
        teamBEn: 'Argentina',
        teamBBn: 'আর্জেন্টিনা',
        teamALogo: 'https://flagcdn.com/w320/br.png',
        teamBLogo: 'https://flagcdn.com/w320/ar.png',
        leagueEn: 'FIFA World Cup Qualifier',
        leagueBn: 'ফিফা বিশ্বকাপ বাছাইপর্ব',
        startTime: today.add(const Duration(days: 1, hours: 21)),
        venueEn: 'Maracanã Stadium',
        venueBn: 'মারাকানা স্টেডিয়াম',
        sport: SportGroups.football,
        channels: channels,
        hints: const <String>['sony sports 1', 'bein sports 2', 'espn'],
      ),
      _fixture(
        id: 'ban-vs-sl',
        teamAEn: 'Bangladesh',
        teamABn: 'বাংলাদেশ',
        teamBEn: 'Sri Lanka',
        teamBBn: 'শ্রীলঙ্কা',
        teamALogo: 'https://flagcdn.com/w320/bd.png',
        teamBLogo: 'https://flagcdn.com/w320/lk.png',
        leagueEn: 'Asia Cup',
        leagueBn: 'এশিয়া কাপ',
        startTime: today.add(const Duration(days: 2, hours: 19)),
        venueEn: 'R. Premadasa Stadium, Colombo',
        venueBn: 'আর. প্রেমাদাসা স্টেডিয়াম, কলম্বো',
        sport: SportGroups.cricket,
        channels: channels,
        hints: const <String>['t sports', 'star sports 2', 'sports18'],
      ),
    ];
  }

  static MatchModel _fixture({
    required String id,
    required String teamAEn,
    required String teamABn,
    required String teamBEn,
    required String teamBBn,
    required String teamALogo,
    required String teamBLogo,
    required String leagueEn,
    required String leagueBn,
    required DateTime startTime,
    required String venueEn,
    required String venueBn,
    required String sport,
    required List<Channel> channels,
    required List<String> hints,
    bool isLive = false,
  }) {
    final channel = _resolveChannel(channels, hints: hints, sport: sport);

    return MatchModel(
      id: id,
      teamA: LocalizedText(en: teamAEn, bn: teamABn),
      teamB: LocalizedText(en: teamBEn, bn: teamBBn),
      teamALogo: teamALogo,
      teamBLogo: teamBLogo,
      league: LocalizedText(en: leagueEn, bn: leagueBn),
      startTime: startTime,
      venue: LocalizedText(en: venueEn, bn: venueBn),
      isLive: isLive,
      channelName: channel?.name ?? '',
      channelLogo: channel?.logo ?? '',
      streamUrls: channel?.playbackUrls ?? const <String>[],
      httpHeaders: _headersFor(channel),
    );
  }

  static Channel? _resolveChannel(
    List<Channel> channels, {
    required List<String> hints,
    required String sport,
  }) {
    if (channels.isEmpty) return null;

    for (final hint in hints) {
      for (final channel in channels) {
        if (channel.name.toLowerCase().contains(hint)) return channel;
      }
    }
    for (final channel in channels) {
      if (channel.sportGroup == sport) return channel;
    }
    return channels.first;
  }

  static Map<String, String> _headersFor(Channel? channel) {
    if (channel == null) return const <String, String>{};
    return <String, String>{
      if ((channel.userAgent ?? '').trim().isNotEmpty)
        'User-Agent': channel.userAgent!.trim(),
      if ((channel.referrer ?? '').trim().isNotEmpty)
        'Referer': channel.referrer!.trim(),
    };
  }

  /// Curated highlight feed with sample playback URLs.
  List<HighlightModel> get highlights {
    final now = DateTime.now();

    return <HighlightModel>[
      HighlightModel(
        id: 'hl-cricket',
        title: const LocalizedText(
          en: 'Bangladesh vs Pakistan: last-over thriller',
          bn: 'বাংলাদেশ বনাম পাকিস্তান: শেষ ওভারের রোমাঞ্চ',
        ),
        thumbnail: 'https://picsum.photos/seed/sportzfy-cricket/900/506',
        streamUrl: _sampleVideoOne,
        duration: const Duration(minutes: 8, seconds: 42),
        publishedAt: now.subtract(const Duration(hours: 3)),
        sport: SportGroups.cricket,
      ),
      HighlightModel(
        id: 'hl-clasico',
        title: const LocalizedText(
          en: 'Real Madrid 3–2 Barcelona: El Clásico highlights',
          bn: 'রিয়াল মাদ্রিদ ৩–২ বার্সেলোনা: ক্লাসিকো হাইলাইটস',
        ),
        thumbnail: 'https://picsum.photos/seed/sportzfy-football/900/506',
        streamUrl: _sampleVideoFour,
        duration: const Duration(minutes: 10, seconds: 18),
        publishedAt: now.subtract(const Duration(days: 1, hours: 2)),
        sport: SportGroups.football,
      ),
      HighlightModel(
        id: 'hl-city',
        title: const LocalizedText(
          en: "Manchester City's stunning winner",
          bn: 'ম্যানচেস্টার সিটির দুর্দান্ত গোল',
        ),
        thumbnail: 'https://picsum.photos/seed/sportzfy-stadium/900/506',
        streamUrl: _sampleVideoFive,
        duration: const Duration(minutes: 5, seconds: 27),
        publishedAt: now.subtract(const Duration(days: 2)),
        sport: SportGroups.football,
      ),
      HighlightModel(
        id: 'hl-tennis',
        title: const LocalizedText(
          en: 'Best moments from the Wimbledon final',
          bn: 'উইম্বলডন ফাইনালের সেরা মুহূর্ত',
        ),
        thumbnail: 'https://picsum.photos/seed/sportzfy-tennis/900/506',
        streamUrl: _sampleVideoTwo,
        duration: const Duration(minutes: 7, seconds: 52),
        publishedAt: now.subtract(const Duration(days: 4)),
        sport: SportGroups.tennis,
      ),
      HighlightModel(
        id: 'hl-brazil',
        title: const LocalizedText(
          en: 'Brazil vs Argentina: a classic battle',
          bn: 'ব্রাজিল বনাম আর্জেন্টিনা: রোমাঞ্চকর লড়াই',
        ),
        thumbnail: 'https://picsum.photos/seed/sportzfy-soccer/900/506',
        streamUrl: _sampleVideoThree,
        duration: const Duration(minutes: 9, seconds: 5),
        publishedAt: now.subtract(const Duration(days: 7)),
        sport: SportGroups.football,
      ),
    ];
  }
}
