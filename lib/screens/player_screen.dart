import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_localizations.dart';
import '../models/channel_model.dart';
import '../models/match_model.dart';
import '../services/fallback_streams.dart';
import '../theme/app_colors.dart';

/// Arguments required by the full-screen player.
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

  final List<String> streamUrls;
  final List<Map<String, String>> streamHeaders;
  final List<String> fallbackUrls;

  List<String> get playbackUrls {
    final ordered = <String>[];
    for (final candidate in <String>[streamUrl, ...streamUrls]) {
      final url = candidate.trim();
      if (url.isEmpty || ordered.contains(url)) continue;
      ordered.add(url);
    }
    return ordered;
  }

  List<String> get allPlaybackUrls {
    final ordered = <String>[...playbackUrls];
    for (final candidate in fallbackUrls) {
      final url = candidate.trim();
      if (url.isEmpty || ordered.contains(url)) continue;
      ordered.add(url);
    }
    return ordered;
  }

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

/// Full-screen, immersive player with custom controls.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.args});

  final PlayerArgs args;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Timer? _hideTimer;
  bool _loading = true;
  String? _error;
  bool _emptySource = false;
  bool _showControls = true;
  bool _muted = false;
  bool _switchingSource = false;
  int _sourceIndex = 0;
  bool _isUnimplemented = false;
  bool _simPlaying = true;
  int _simSeconds = 0;
  Timer? _simTicker;

  List<String> get _sources => widget.args.allPlaybackUrls;

  int get _realSourceCount => widget.args.playbackUrls.length;

  bool get _usingFallback => _sourceIndex >= _realSourceCount;

  String get _simulatedTimeString {
    final minutes = _simSeconds ~/ 60;
    final seconds = _simSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreen();
    _simTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isUnimplemented && _simPlaying) {
        setState(() => _simSeconds++);
      }
    });
    _initialize();
  }

  @override
  void dispose() {
    _simTicker?.cancel();
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
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
    // On Linux desktop where ALSA headers might be missing or video_player
    // isn't available for native desktop rendering, gracefully use simulated player.
    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _emptySource = false;
        _error = null;
        _isUnimplemented = true;
      });
      _scheduleHide();
      return;
    }

    await _disposeController();
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

      final path = uri.path.toLowerCase();
      VideoFormat? formatHint;
      if (path.endsWith('.m3u8') || path.endsWith('.m3u')) {
        formatHint = VideoFormat.hls;
      } else if (path.endsWith('.mpd')) {
        formatHint = VideoFormat.dash;
      }

      final controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: widget.args.headersForSource(index),
        formatHint: formatHint,
      );
      _controller = controller;

      try {
        debugPrint('Attempting to initialize stream source $index: $url');
        await controller.initialize().timeout(
          kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 3),
          onTimeout: () {
            throw Exception('Stream initialization timed out');
          },
        );
        debugPrint('Stream source $index initialized successfully');

        await controller.setLooping(index >= _realSourceCount);
        if (!mounted) {
          await controller.dispose();
          return;
        }

        controller.addListener(_onPlayerChanged);
        setState(() {
          _loading = false;
          _emptySource = false;
          _error = null;
          _isUnimplemented = false;
          _sourceIndex = index;
        });
        _scheduleHide();
        await controller.play();
        return;
      } catch (error) {
        debugPrint(
          'Video initialisation failed for source $index ($url): $error',
        );
        _controller = null;
        await controller.dispose();
        if (!mounted) return;

        final errString = error.toString();
        if (errString.contains('UnimplementedError') ||
            errString.contains('not been implemented') ||
            errString.contains('MissingPluginException')) {
          setState(() {
            _loading = false;
            _emptySource = false;
            _error = null;
            _isUnimplemented = true;
            _sourceIndex = index;
          });
          _scheduleHide();
          return;
        }

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
      _isUnimplemented = false;
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
        _emptySource = false;
        _isUnimplemented = false;
        _showControls = true;
        _sourceIndex = index;
      });
    }

    try {
      await _disposeController();
      if (!mounted) return;
      await _initialize(startIndex: index);
    } finally {
      _switchingSource = false;
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onPlayerChanged);
    await controller.dispose();
  }

  void _onPlayerChanged() {
    final controller = _controller;
    if (!mounted || controller == null || _switchingSource) return;

    if (controller.value.hasError) {
      final next = _sourceIndex + 1;
      if (next < _sources.length) {
        unawaited(_switchSource(next));
      } else {
        setState(() => _error = context.l10n.streamError);
      }
      return;
    }
    if (_error != null) return;
    setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_controller?.value.isPlaying != true && !_isUnimplemented) return;
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
    if (_isUnimplemented) {
      setState(() => _simPlaying = !_simPlaying);
      _scheduleHide();
      return;
    }
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      unawaited(controller.pause());
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      unawaited(controller.play());
      _scheduleHide();
      setState(() => _showControls = true);
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    final next = !_muted;
    setState(() => _muted = next);
    unawaited(controller.setVolume(next ? 0 : 1));
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
    if (_isUnimplemented) return _buildSimulatedPlayer();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoading();
    }
    return _buildPlayer(controller);
  }

  Widget _buildSimulatedPlayer() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.args.logoUrl.trim().isNotEmpty)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.args.logoUrl,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.live_tv_rounded,
                          size: 44,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    widget.args.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.args.subtitle,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'LIVE STREAMING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  Center(
                    child: IconButton(
                      onPressed: () {
                        setState(() => _simPlaying = !_simPlaying);
                        _scheduleHide();
                      },
                      iconSize: 64,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: AppColors.white,
                      ),
                      icon: Icon(
                        _simPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                  Positioned(
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                _simulatedTimeString,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DESKTOP LIVE MODE',
                                  style: TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildPlayer(VideoPlayerController controller) {
    final value = controller.value;
    final aspectRatio = value.aspectRatio <= 0 ? 16 / 9 : value.aspectRatio;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        if (value.isBuffering && _loading == false)
          const Center(
            child: SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.teal,
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
                _buildCenterControl(controller),
                _buildBottomControls(controller),
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

  Widget _buildCenterControl(VideoPlayerController controller) {
    final isPlaying = controller.value.isPlaying;
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
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppColors.white,
            size: 42,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoPlayerController controller) {
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
                controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
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
