import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel_model.dart';
import '../models/highlight_model.dart';
import '../models/match_model.dart';
import '../repository/iptv_repository.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

enum IptvStatus { initial, loading, success, error }

class IptvState {
  const IptvState({
    this.status = IptvStatus.initial,
    this.channels = const <Channel>[],
    this.allChannels = const <Channel>[],
    this.sportFilters = const <String>[SportGroups.all],
    this.searchQuery = '',
    this.selectedSport = SportGroups.all,
    this.matches = const <MatchModel>[],
    this.highlights = const <HighlightModel>[],
    this.failure,
    this.isRefreshing = false,
    this.networkFailed = false,
    this.fromCache = false,
    this.lastUpdatedAt,
  });

  final IptvStatus status;

  /// Channels after applying search and sport filters.
  final List<Channel> channels;

  /// All merged sports channels.
  final List<Channel> allChannels;

  final List<String> sportFilters;
  final String searchQuery;
  final String selectedSport;

  final List<MatchModel> matches;
  final List<HighlightModel> highlights;

  /// Machine-readable failure; the UI localizes it for English or Bangla.
  final AppFailureType? failure;
  final bool isRefreshing;
  final bool networkFailed;
  final bool fromCache;
  final DateTime? lastUpdatedAt;

  bool get isInitialLoading =>
      status == IptvStatus.loading && allChannels.isEmpty;

  bool get hasBlockingError =>
      status == IptvStatus.error && allChannels.isEmpty;

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty || selectedSport != SportGroups.all;

  List<MatchModel> get liveMatches =>
      matches.where((match) => match.isLive).toList(growable: false);

  List<MatchModel> get upcomingMatches =>
      matches.where((match) => !match.isLive).toList(growable: false);

  static const Object _unset = Object();

  IptvState copyWith({
    IptvStatus? status,
    List<Channel>? channels,
    List<Channel>? allChannels,
    List<String>? sportFilters,
    String? searchQuery,
    String? selectedSport,
    List<MatchModel>? matches,
    List<HighlightModel>? highlights,
    Object? failure = _unset,
    bool? isRefreshing,
    bool? networkFailed,
    bool? fromCache,
    DateTime? lastUpdatedAt,
  }) {
    return IptvState(
      status: status ?? this.status,
      channels: channels ?? this.channels,
      allChannels: allChannels ?? this.allChannels,
      sportFilters: sportFilters ?? this.sportFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSport: selectedSport ?? this.selectedSport,
      matches: matches ?? this.matches,
      highlights: highlights ?? this.highlights,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as AppFailureType?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      networkFailed: networkFailed ?? this.networkFailed,
      fromCache: fromCache ?? this.fromCache,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class IptvNotifier extends StateNotifier<IptvState> {
  IptvNotifier(this._repository)
    : super(
        IptvState(
          matches: _repository.buildMatches(const <Channel>[]),
          highlights: _repository.highlights,
        ),
      ) {
    load();
  }

  final IptvRepository _repository;
  int _requestId = 0;

  Future<void> load({bool refresh = false}) async {
    final requestId = ++_requestId;

    if (refresh && state.allChannels.isNotEmpty) {
      state = state.copyWith(isRefreshing: true, failure: null);
    } else {
      state = state.copyWith(
        status: IptvStatus.loading,
        isRefreshing: false,
        networkFailed: false,
        fromCache: false,
        failure: null,
      );
    }

    try {
      final result = await _repository.loadCatalog(forceRefresh: refresh);
      if (!mounted || requestId != _requestId) return;

      final filters = _buildSportFilters(result.channels);
      final selectedSport = filters.contains(state.selectedSport)
          ? state.selectedSport
          : SportGroups.all;

      state = state.copyWith(
        status: IptvStatus.success,
        isRefreshing: false,
        allChannels: result.channels,
        channels: _applyFilters(
          result.channels,
          state.searchQuery,
          selectedSport,
        ),
        sportFilters: filters,
        selectedSport: selectedSport,
        matches: _repository.buildMatches(result.channels),
        networkFailed: result.networkFailed,
        fromCache: result.fromCache,
        lastUpdatedAt: result.savedAt,
        failure: null,
      );
    } catch (error) {
      if (!mounted || requestId != _requestId) return;

      final failure = error is AppException
          ? error.type
          : AppFailureType.unknown;
      if (state.allChannels.isNotEmpty) {
        // Keep existing data visible and surface the offline banner instead of
        // replacing the whole screen with an error state.
        state = state.copyWith(
          status: IptvStatus.success,
          isRefreshing: false,
          networkFailed: failure == AppFailureType.network,
          failure: failure,
        );
      } else {
        state = state.copyWith(
          status: IptvStatus.error,
          isRefreshing: false,
          networkFailed: failure == AppFailureType.network,
          failure: failure,
        );
      }
    }
  }

  Future<void> refresh() => load(refresh: true);

  void setSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      channels: _applyFilters(state.allChannels, value, state.selectedSport),
    );
  }

  void setSportFilter(String sport) {
    if (sport == state.selectedSport) return;
    state = state.copyWith(
      selectedSport: sport,
      channels: _applyFilters(state.allChannels, state.searchQuery, sport),
    );
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedSport: SportGroups.all,
      channels: _applyFilters(state.allChannels, '', SportGroups.all),
    );
  }

  static List<String> _buildSportFilters(List<Channel> channels) {
    final present = channels.map((channel) => channel.sportGroup).toSet();
    return <String>[
      SportGroups.all,
      ...SportGroups.ordered.where(present.contains),
    ];
  }

  static List<Channel> _applyFilters(
    List<Channel> channels,
    String query,
    String sport,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    return channels
        .where((channel) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              channel.name.toLowerCase().contains(normalizedQuery);
          final matchesSport =
              sport == SportGroups.all || channel.sportGroup == sport;
          return matchesQuery && matchesSport;
        })
        .toList(growable: false);
  }

}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Overridden in `main()` with a Hive-backed instance.
final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError(
    'cacheServiceProvider must be overridden in main().',
  );
});

final iptvRepositoryProvider = Provider<IptvRepository>((ref) {
  return IptvRepository(
    api: ref.watch(apiServiceProvider),
    cache: ref.watch(cacheServiceProvider),
  );
});

final iptvProvider = StateNotifierProvider<IptvNotifier, IptvState>((ref) {
  return IptvNotifier(ref.watch(iptvRepositoryProvider));
});
