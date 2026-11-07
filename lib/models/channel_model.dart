/// Language-independent channel buckets used by the category filter chips.
///
/// The UI maps these ids to English or Bangla labels through
/// `AppLocalizations.sportLabel`.
abstract final class SportGroups {
  static const String all = 'all';
  static const String cricket = 'cricket';
  static const String football = 'football';
  static const String tennis = 'tennis';
  static const String golf = 'golf';
  static const String racing = 'racing';
  static const String fighting = 'fighting';
  static const String other = 'other';

  /// Display order for filters (excluding "all").
  static const List<String> ordered = <String>[
    cricket,
    football,
    tennis,
    golf,
    racing,
    fighting,
    other,
  ];
}

/// A merged IPTV channel.
///
/// Data comes from `channels.json`, `streams.json`, `logos.json` and
/// `feeds.json`, joined by the channel ID.
class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
    required this.category,
    this.country,
    this.quality,
    this.userAgent,
    this.referrer,
    this.streams = const <String>[],
    this.streamHeaders = const <Map<String, String>>[],
  });

  final String id;
  final String name;
  final String logo;
  final String streamUrl;

  /// Raw iptv-org category (for this app it is always `sports`).
  final String category;

  final String? country;
  final String? quality;
  final String? userAgent;
  final String? referrer;

  /// Every playable URL for this channel, best source first.
  ///
  /// The player walks through the list automatically when a source fails, so a
  /// channel is not limited to the single URL that won the merge ranking.
  final List<String> streams;

  /// Request headers aligned with [streams] from the upstream catalog.
  final List<Map<String, String>> streamHeaders;

  bool get hasLogo => logo.trim().isNotEmpty;
  bool get hasStream => playbackUrls.isNotEmpty;

  /// Ordered, de-duplicated list of URLs the player can try.
  List<String> get playbackUrls {
    final ordered = <String>[];
    for (final candidate in <String>[streamUrl, ...streams]) {
      final url = candidate.trim();
      if (url.isEmpty || ordered.contains(url)) continue;
      ordered.add(url);
    }
    return ordered;
  }

  String get countryFlagEmoji {
    final code = country;
    if (code == null || code.length != 2) return '';
    final upper = code.toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(upper)) return '';
    return String.fromCharCodes(
      upper.codeUnits.map((unit) => 0x1F1E6 + (unit - 0x41)),
    );
  }

  /// A best-effort sports bucket inferred from the channel name.
  ///
  /// iptv-org only exposes a generic `sports` category, so the app groups
  /// familiar sports channels into Bangla filter buckets.
  String get sportGroup {
    final value = name.toLowerCase();

    bool hasAny(List<String> keywords) =>
        keywords.any((keyword) => value.contains(keyword));

    if (hasAny(const <String>[
      'cricket',
      'icc ',
      'icc',
      'bpl',
      'ipl',
      'psl',
      'cpl',
      'willow',
      'star sports',
      'sports18',
      'ten sports',
      't sports',
      'supersport cricket',
      'sky cricket',
      'fox cricket',
      'espn cricket',
      'cricket gold',
    ])) {
      return SportGroups.cricket;
    }

    if (hasAny(const <String>[
      'football',
      'soccer',
      'fifa',
      'uefa',
      'premier league',
      'la liga',
      'laliga',
      'serie a',
      'bundesliga',
      'ligue 1',
      'champions league',
      'bein sport',
      'sky sport football',
      'sky sports',
      'espn',
      'fox soccer',
      'goal tv',
      'astro supersport',
    ])) {
      return SportGroups.football;
    }

    if (hasAny(const <String>[
      'tennis',
      'wimbledon',
      'atp',
      'wta',
      'roland garros',
      'us open tennis',
    ])) {
      return SportGroups.tennis;
    }

    if (hasAny(const <String>['golf', 'pga', 'lpga', 'masters golf'])) {
      return SportGroups.golf;
    }

    if (hasAny(const <String>[
      'racing',
      'formula',
      'f1',
      'nascar',
      'motogp',
      'motorvision',
      'motorsport',
      'drag race',
      'speed channel',
    ])) {
      return SportGroups.racing;
    }

    if (hasAny(const <String>[
      'boxing',
      'ufc',
      'wwe',
      'mma',
      'fight',
      'combat',
      'wrestling',
    ])) {
      return SportGroups.fighting;
    }

    return SportGroups.other;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'logo': logo,
    'streamUrl': streamUrl,
    'category': category,
    'country': country,
    'quality': quality,
    'userAgent': userAgent,
    'referrer': referrer,
    'streams': streams,
    'streamHeaders': streamHeaders,
  };

  factory Channel.fromJson(Map<String, dynamic> json) {
    final rawStreams = json['streams'];
    return Channel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      streamUrl: json['streamUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'sports',
      country: json['country'] as String?,
      quality: json['quality'] as String?,
      userAgent: json['userAgent'] as String?,
      referrer: json['referrer'] as String?,
      streams: rawStreams is List
          ? rawStreams.whereType<String>().toList(growable: false)
          : const <String>[],
      streamHeaders:
          (json['streamHeaders'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, String>.from(item))
              .toList(growable: false) ??
          const <Map<String, String>>[],
    );
  }

  Channel copyWith({
    String? id,
    String? name,
    String? logo,
    String? streamUrl,
    String? category,
    String? country,
    String? quality,
    String? userAgent,
    String? referrer,
    List<String>? streams,
    List<Map<String, String>>? streamHeaders,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      streamUrl: streamUrl ?? this.streamUrl,
      category: category ?? this.category,
      country: country ?? this.country,
      quality: quality ?? this.quality,
      userAgent: userAgent ?? this.userAgent,
      referrer: referrer ?? this.referrer,
      streams: streams ?? this.streams,
      streamHeaders: streamHeaders ?? this.streamHeaders,
    );
  }
}
