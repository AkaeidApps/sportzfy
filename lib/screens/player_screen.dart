import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../l10n/app_localizations.dart';
import '../models/channel_model.dart';
import '../models/match_model.dart';
import '../services/fallback_streams.dart';
import '../theme/app_colors.dart';

/// Arguments required by the full-screen player.
///
/// A channel or match can expose several fallback URLs. The player starts with
/// the best-ranked source and walks through the rest automatically when one
/// provider is down.
class PlayerArgs {
  static const String _browserUserAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

  const PlayerArgs({
    required this.title,
    required this.streamUrl,
    this.subtitle = '',
    this.logoUrl = '',
    this.httpHeaders = const <String, String>{},
    this.isLive = false,
    this.streamUrls = const <String>[],
    this.streamHeaders = const <Map<String, String>>[],
    this.fallbackUrls = const <String>[],
  });

  final String title;
  final String subtitle;
  final String streamUrl;
  final String logoUrl;
  final Map<String, String> httpHeaders;
  final bool isLive;

  /// Additional mirror URLs, best source first.
  final List<String> streamUrls;
  final List<Map<String, String>> streamHeaders;

  /// Public backup videos tried after every real channel mirror fails.
  ///
  /// This keeps every channel playable even when its upstream provider is
  /// offline, geo-blocked or expired.
  final List<String> fallbackUrls;

  /// Ordered, de-duplicated list of URLs the player can try.
  List<String> get playbackUrls {
    final ordered = <String>[];
    for (final candidate in <String>[streamUrl, ...streamUrls]) {
      final url = candidate.trim();
      if (url.isEmpty || ordered.contains(url)) continue;
      ordered.add(url);
    }
    return ordered;
  }

  /// Real mirrors followed by the public backup videos.
  ///
  /// The player walks this complete list, so a dead provider automatically
  /// falls through to a working backup clip instead of stopping on an error.
  List<String> get allPlaybackUrls {
    final ordered = <String>[...playbackUrls];
    for (final candidate in fallbackUrls) {
      final url = candidate.trim();
      if (url.isEmpty || ordered.contains(url)) continue;
      ordered.add(url);
    }
    return ordered;
  }

  /// Whether [index] points at a backup video rather than the real channel.
  bool isFallbackSource(int index) =>
      index >= playbackUrls.length && index < allPlaybackUrls.length;

  Map<String, String> headersForSource(int index) {
    if (isFallbackSource(index)) return const <String, String>{};
    final headers = index >= 0 && index < streamHeaders.length
        ? Map<String, String>.of(streamHeaders[index])
        : Map<String, String>.of(httpHeaders);
    final hasUserAgent = headers.keys.any(
      (key) => key.toLowerCase() == 'user-agent',
    );
    if (!kIsWeb && !hasUserAgent) {
      headers['User-Agent'] = _browserUserAgent;
    }
    return headers;
  }

  factory PlayerArgs.fromChannel(
    Channel channel, {
    required AppLocalizations l10n,
  }) {
    final headers = <String, String>{
      if ((channel.userAgent ?? '').trim().isNotEmpty)
        'User-Agent': channel.userAgent!.trim(),
      if ((channel.referrer ?? '').trim().isNotEmpty)
        'Referer': channel.referrer!.trim(),
    };
    final subtitleParts = <String>[
      l10n.liveSportsChannel,
      if ((channel.quality ?? '').isNotEmpty) channel.quality!,
      if ((channel.country ?? '').isNotEmpty) channel.country!.toUpperCase(),
    ];
    final urls = channel.playbackUrls;

    return PlayerArgs(
      title: channel.name,
      subtitle: subtitleParts.join(' • '),
      streamUrl: urls.isEmpty ? '' : urls.first,
      streamUrls: urls,
      streamHeaders: channel.streamHeaders,
      logoUrl: channel.logo,
      httpHeaders: headers,
      isLive: true,
      fallbackUrls: FallbackStreams.urls,
    );
  }

  factory PlayerArgs.fromMatch(MatchModel match, AppLocalizations l10n) {
    final subtitleParts = <String>[
      match.leagueFor(l10n.language),
      match.isLive ? l10n.live : l10n.upcoming,
    ];
    final urls = match.streamUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    return PlayerArgs(
      title:
          '${match.teamAFor(l10n.language)} ${l10n.vs} '
          '${match.teamBFor(l10n.language)}',
      subtitle: subtitleParts
          .where((part) => part.trim().isNotEmpty)
          .join(' • '),
      streamUrl: urls.isEmpty ? '' : urls.first,
      streamUrls: urls,
      fallbackUrls: FallbackStreams.urls,
      logoUrl: match.channelLogo,
      httpHeaders: match.httpHeaders,
      isLive: match.isLive,
    );
  }

  factory PlayerArgs.fromQuery(Map<String, String> query) {
    return PlayerArgs(
      title: query['title'] ?? 'Sportzfy',
      subtitle: query['subtitle'] ?? '',
      streamUrl: query['url'] ?? '',
      logoUrl: query['logo'] ?? '',
      isLive: query['live'] == '1' || query['live'] == 'true',
      fallbackUrls: FallbackStreams.urls,
    );
  }
}

/// Full-screen, immersive player powered by media_kit.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.args});

  final PlayerArgs args;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);
  Timer? _hideTimer;
  bool _loading = true;
  String? _error;
  bool _emptySource = false;
  bool _showControls = true;
  bool _muted = false;
  bool _switchingSource = false;
  int _sourceIndex = 0;
  bool _isPlaying = true;

  List<String> get _sources => widget.args.allPlaybackUrls;

  int get _realSourceCount => widget.args.playbackUrls.length;

  bool get _usingFallback => _sourceIndex >= _realSourceCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreen();
    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });
    _initialize();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_player.dispose());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _player.pause();
      _hideTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _enterFullscreen();
    }
  }

  void _enterFullscreen() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _initialize({int startIndex = 0}) async {
    final sources = _sources;
    final firstIndex = startIndex
        .clamp(0, sources.isEmpty ? 0 : sources.length - 1)
        .toInt();

    if (sources.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _emptySource = true;
        _error = context.l10n.emptyStream;
      });
      return;
    }

    for (var index = firstIndex; index < sources.length; index++) {
      if (!mounted) return;
      setState(() => _sourceIndex = index);

      final url = sources[index].trim();
      final uri = Uri.tryParse(url);
      final isValidUrl =
          uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;

      if (!isValidUrl) continue;

      try {
        debugPrint('Attempting to open media_kit source $index: $url');
        await _player.open(
          Media(
            url,
            httpHeaders: widget.args.headersForSource(index),
          ),
        ).timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            throw Exception('Stream initialization timed out after 4s');
          },
        );
        debugPrint('media_kit source $index opened successfully');

        await _player.play();
        if (!mounted) return;

        setState(() {
          _loading = false;
          _emptySource = false;
          _error = null;
          _sourceIndex = index;
        });
        _scheduleHide();
        return;
      } catch (error) {
        debugPrint('media_kit initialisation failed for source $index ($url): $error');
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _emptySource = false;
      _error = context.l10n.streamError;
    });
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
      _emptySource = false;
      _showControls = true;
      _sourceIndex = 0;
    });
    await _initialize(startIndex: 0);
  }

  Future<void> _switchSource(int index) async {
    if (_switchingSource) return;
    final sources = _sources;
    if (index < 0 || index >= sources.length) return;

    _switchingSource = true;
    _hideTimer?.cancel();
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _showControls = true;
        _sourceIndex = index;
      });
    }

    try {
      if (!mounted) return;
      await _initialize(startIndex: index);
    } finally {
      _switchingSource = false;
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    _hideTimer?.cancel();
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlayback() {
    _player.playOrPause();
    _scheduleHide();
    setState(() => _showControls = true);
  }

  void _toggleMute() {
    final next = !_muted;
    setState(() => _muted = next);
    _player.setVolume(next ? 0.0 : 100.0);
  }

  void _exitPlayer() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildPlayer();
  }

  Widget _buildLoading() {
    final l10n = context.l10n;
    final total = _sources.length;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildBackButton(),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _usingFallback
                      ? l10n.loadingBackup
                      : total > 1
                      ? l10n.tryingSource(
                          (_sourceIndex + 1).clamp(1, total).toInt(),
                          total,
                        )
                      : l10n.streamLoading,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.args.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final l10n = context.l10n;
    final title = _emptySource ? l10n.emptyStream : l10n.streamError;
    final total = _sources.length;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildBackButton(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.live.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_disabled_rounded,
                    color: AppColors.live,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emptySource ? l10n.emptyStream : l10n.streamErrorHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (total > 1) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    l10n.sourceOf(_sourceIndex + 1, total),
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                    ),
                    if (total > 1) ...<Widget>[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          final next = (_sourceIndex + 1) % total;
                          unawaited(_switchSource(next));
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: Text(l10n.switchSource),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _exitPlayer,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: Text(l10n.back),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 8,
      left: 8,
      child: IconButton(
        onPressed: _exitPlayer,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          foregroundColor: AppColors.white,
        ),
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: context.l10n.back,
      ),
    );
  }

  Widget _buildPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Center(
            child: Video(
              controller: _videoController,
              fit: BoxFit.contain,
              controls: NoVideoControls,
            ),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _showControls ? 1 : 0,
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildTopBar(),
                _buildCenterControl(),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final l10n = context.l10n;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 16, 34),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              onPressed: _exitPlayer,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.white,
              tooltip: l10n.back,
            ),
            if (widget.args.logoUrl.trim().isNotEmpty) ...<Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.darkElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(4),
                child: CachedNetworkImage(
                  imageUrl: widget.args.logoUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: 120,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.live_tv_rounded,
                    size: 18,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.args.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.args.subtitle.isNotEmpty)
                    Text(
                      widget.args.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (_usingFallback)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.backupStream,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (widget.args.isLive)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.circle, color: AppColors.white, size: 6),
                    const SizedBox(width: 5),
                    Text(
                      l10n.live,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControl() {
    return Center(
      child: GestureDetector(
        onTap: _togglePlayback,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppColors.white,
            size: 42,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: _togglePlayback,
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
