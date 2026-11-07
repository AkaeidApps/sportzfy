import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/channel_model.dart';
import '../models/match_model.dart';
import '../providers/iptv_provider.dart';
import '../routes/app_routes.dart';
import '../screens/player_screen.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/connection_banner.dart';
import '../widgets/match_card.dart';
import '../widgets/pressable.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(iptvProvider);
    final notifier = ref.read(iptvProvider.notifier);
    final liveMatches = state.liveMatches;
    final upcomingMatches = state.upcomingMatches;
    final showChannelStrip = state.channels.isNotEmpty;

    void showReminder() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.reminderSet)));
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.teal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _HomeHeader(
            state: state,
            onRetry: notifier.refresh,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: l10n.liveMatches,
            count: liveMatches.length,
            icon: Icons.sensors_rounded,
            accent: AppColors.live,
          ),
          const SizedBox(height: 10),
          if (liveMatches.isEmpty)
            _EmptyState(
              icon: Icons.sports_rounded,
              title: l10n.liveEmptyTitle,
              subtitle: l10n.liveEmptySubtitle,
              accent: AppColors.live,
            )
          else
            for (final match in liveMatches)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchCard(
                  match: match,
                  onAction: () => _openMatch(context, match),
                ),
              ),
          const SizedBox(height: 8),
          _SectionHeader(
            title: l10n.upcomingMatches,
            count: upcomingMatches.length,
            icon: Icons.calendar_month_rounded,
            accent: AppColors.accent,
            actionLabel: l10n.viewAll,
            onAction: () => context.go(AppRoutes.schedule),
          ),
          const SizedBox(height: 10),
          if (upcomingMatches.isEmpty)
            _EmptyState(
              icon: Icons.event_busy_rounded,
              title: l10n.upcomingEmptyTitle,
              subtitle: l10n.upcomingEmptySubtitle,
              accent: AppColors.accent,
            )
          else
            for (final match in upcomingMatches.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchCard(
                  match: match,
                  onAction: showReminder,
                ),
              ),
          if (showChannelStrip) ...<Widget>[
            const SizedBox(height: 8),
            _ChannelStrip(
              channels: state.channels,
              onOpenChannel: (channel) => _openChannel(context, channel),
              onViewAll: () => context.go(AppRoutes.category),
            ),
          ],
        ],
      ),
    );
  }

  void _openMatch(BuildContext context, MatchModel match) {
    final l10n = context.l10n;
    if (!match.canPlay) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.channelUnavailable),
          ),
        );
      return;
    }

    context.pushNamed(
      AppRoutes.playerName,
      extra: PlayerArgs.fromMatch(match, l10n),
    );
  }

  void _openChannel(BuildContext context, Channel channel) {
    context.pushNamed(
      AppRoutes.playerName,
      extra: PlayerArgs.fromChannel(channel, l10n: context.l10n),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state, required this.onRetry});

  final IptvState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final liveCount = state.liveMatches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.welcome,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.liveMatches,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 25,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            _LiveCountPill(count: liveCount),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          l10n.liveMatchesSubtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 15),
        const _HeroBanner(),
        const SizedBox(height: 13),
        _buildStatus(context),
        if (state.status == IptvStatus.success &&
            state.allChannels.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.bolt_rounded,
                size: 13,
                color: AppColors.teal,
              ),
              const SizedBox(width: 5),
              Text(
                l10n.loadedChannelCount(state.allChannels.length),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatus(BuildContext context) {
    final l10n = context.l10n;
    if (state.status == IptvStatus.loading && state.allChannels.isEmpty) {
      return Row(
        children: <Widget>[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.loadingChannels,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (state.status == IptvStatus.error) {
      return ConnectionBanner(
        message: _failureTitle(context, state),
        isError: true,
        onRetry: onRetry,
      );
    }

    if (state.networkFailed) {
      return ConnectionBanner(
        message: l10n.cachedBanner,
        icon: Icons.cloud_off_rounded,
        onRetry: onRetry,
      );
    }

    return const SizedBox.shrink();
  }

  static String _failureTitle(BuildContext context, IptvState state) {
    final l10n = context.l10n;
    return switch (state.failure) {
      AppFailureType.server => l10n.serverError,
      AppFailureType.parse => l10n.parseError,
      AppFailureType.unknown => l10n.unknownError,
      _ => l10n.noInternet,
    };
  }
}

class _LiveCountPill extends StatelessWidget {
  const _LiveCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.live.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.live.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LivePulseDot(size: 7),
          const SizedBox(width: 6),
          Text(
            context.l10n.liveCountLabel(count),
            style: const TextStyle(
              color: AppColors.live,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0A1628),
            Color(0xFF0D2137),
            Color(0xFF091A2A),
          ],
        ),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.22),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          // Color grading overlay - warm to cool gradient
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (_) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF00B4D8),
                  Color(0xFF0077B6),
                  Color(0xFF023E8A),
                ],
              ).createShader(const Rect.fromLTWH(0, 0, 400, 200)),
              blendMode: BlendMode.overlay,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Decorative circles for depth
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.teal.withValues(alpha: 0.18),
                    AppColors.teal.withValues(alpha: 0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.accent.withValues(alpha: 0.14),
                    AppColors.accent.withValues(alpha: 0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Sports stadium light beams
          Positioned(
            right: 10,
            top: 0,
            child: CustomPaint(
              size: const Size(120, 110),
              painter: _StadiumLightsPainter(),
            ),
          ),
          // Large sports icon watermark
          Positioned(
            right: 14,
            top: 10,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 58,
              color: AppColors.teal.withValues(alpha: 0.15),
            ),
          ),
          // Secondary sports icon
          Positioned(
            right: 70,
            bottom: 8,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 34,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
          ),
          // Content area with constrained height
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    l10n.live.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accentSoft,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    l10n.heroTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    l10n.heroSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StadiumLightsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Draw light beam cones
    for (var i = 0; i < 3; i++) {
      final startX = (10 + i * 35).toDouble();
      final path = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX - 15, size.height)
        ..lineTo(startX + 15, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: accent),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.digits(count),
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelStrip extends StatelessWidget {
  const _ChannelStrip({
    required this.channels,
    required this.onOpenChannel,
    required this.onViewAll,
  });

  final List<Channel> channels;
  final ValueChanged<Channel> onOpenChannel;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visible = channels.take(10).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                size: 15,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.sportsChannels,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                l10n.viewAll,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _MiniChannel(
                channel: visible[index],
                onTap: () => onOpenChannel(visible[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniChannel extends StatelessWidget {
  const _MiniChannel({required this.channel, required this.onTap});

  final Channel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const <Color>[Color(0xFF181823), Color(0xFF0B0B12)]
                      : const <Color>[AppColors.white, Color(0xFFF2F8F9)],
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Pressable(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                semanticsLabel: channel.name,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: channel.hasLogo
                      ? CachedNetworkImage(
                          imageUrl: channel.logo,
                          fit: BoxFit.contain,
                          memCacheWidth: 240,
                          fadeInDuration: const Duration(milliseconds: 180),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.live_tv_rounded,
                            color: AppColors.teal,
                            size: 30,
                          ),
                        )
                      : const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.teal,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            channel.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
