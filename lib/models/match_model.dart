import '../l10n/app_language.dart';
import '../l10n/localized_text.dart';

/// A live or upcoming match shown on the home and schedule screens.
///
/// The supplied iptv-org endpoints do not provide fixtures, so the learning
/// project ships a small curated demo schedule. Live fixtures are linked to a
/// real sports channel from the loaded catalog, which means the play button
/// opens the same production player as the channel grid.
class MatchModel {
  const MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.teamALogo,
    required this.teamBLogo,
    required this.league,
    required this.startTime,
    this.venue = LocalizedText.empty,
    this.isLive = false,
    this.channelName = '',
    this.channelLogo = '',
    this.streamUrls = const <String>[],
    this.httpHeaders = const <String, String>{},
  });

  final String id;
  final LocalizedText teamA;
  final LocalizedText teamB;
  final String teamALogo;
  final String teamBLogo;
  final LocalizedText league;
  final DateTime startTime;
  final LocalizedText venue;
  final bool isLive;

  /// The TV channel carrying the match (used as the player subtitle).
  final String channelName;
  final String channelLogo;

  /// All playable URLs for the linked channel, best source first.
  final List<String> streamUrls;

  /// Headers required by some public IPTV providers.
  final Map<String, String> httpHeaders;

  bool get canPlay => streamUrls.any((url) => url.trim().isNotEmpty);

  String get teamAText => teamA.en;
  String get teamBText => teamB.en;

  String teamAFor(AppLanguage language) => teamA.resolve(language);
  String teamBFor(AppLanguage language) => teamB.resolve(language);
  String leagueFor(AppLanguage language) => league.resolve(language);
  String venueFor(AppLanguage language) => venue.resolve(language);

  MatchModel copyWith({
    String? id,
    LocalizedText? teamA,
    LocalizedText? teamB,
    String? teamALogo,
    String? teamBLogo,
    LocalizedText? league,
    DateTime? startTime,
    LocalizedText? venue,
    bool? isLive,
    String? channelName,
    String? channelLogo,
    List<String>? streamUrls,
    Map<String, String>? httpHeaders,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      teamALogo: teamALogo ?? this.teamALogo,
      teamBLogo: teamBLogo ?? this.teamBLogo,
      league: league ?? this.league,
      startTime: startTime ?? this.startTime,
      venue: venue ?? this.venue,
      isLive: isLive ?? this.isLive,
      channelName: channelName ?? this.channelName,
      channelLogo: channelLogo ?? this.channelLogo,
      streamUrls: streamUrls ?? this.streamUrls,
      httpHeaders: httpHeaders ?? this.httpHeaders,
    );
  }
}
