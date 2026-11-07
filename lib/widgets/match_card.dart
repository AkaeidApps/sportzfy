import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/match_model.dart';
import '../theme/app_colors.dart';
import 'pressable.dart';

/// A rich live/upcoming match card used by the home and schedule screens.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onAction,
    this.showAction = true,
  });

  final MatchModel match;
  final VoidCallback onAction;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[Color(0xFF14141F), Color(0xFF0B0B12)]
              : const <Color>[AppColors.white, Color(0xFFF6FAFB)],
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? (match.isLive
                      ? AppColors.live.withValues(alpha: 0.07)
                      : AppColors.teal.withValues(alpha: 0.05))
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Pressable(
        onTap: onAction,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    match.isLive
                        ? Icons.sports_cricket_rounded
                        : Icons.event_rounded,
                    size: 15,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      match.leagueFor(l10n.language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(isLive: match.isLive),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _Team(
                      name: match.teamAFor(l10n.language),
                      logo: match.teamALogo,
                      textColor: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        l10n.vs,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.tealSoft
                              : AppColors.tealDeep,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _Team(
                      name: match.teamBFor(l10n.language),
                      logo: match.teamBLogo,
                      textColor: primaryText,
                      secondaryText: secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.025)
                      : AppColors.teal.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.formatMatchDateTime(match.startTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!match.isLive) ...<Widget>[
                      const SizedBox(width: 8),
                      _Countdown(startTime: match.startTime),
                    ] else
                      const _LiveLabel(),
                  ],
                ),
              ),
              if (match.venue.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        match.venueFor(l10n.language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (match.channelName.isNotEmpty) ...<Widget>[
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    _ChannelChip(
                      name: match.channelName,
                      logo: match.channelLogo,
                    ),
                    const Spacer(),
                    if (match.isLive && !match.canPlay)
                      Text(
                        l10n.noChannelStream,
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
              if (showAction) ...<Widget>[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: match.isLive
                      ? FilledButton.icon(
                          onPressed: onAction,
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 18,
                          ),
                          label: Text(l10n.watchLive),
                        )
                      : OutlinedButton.icon(
                          onPressed: onAction,
                          icon: const Icon(
                            Icons.notifications_active_rounded,
                            size: 17,
                          ),
                          label: Text(l10n.remindMe),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team({
    required this.name,
    required this.logo,
    required this.textColor,
    required this.secondaryText,
  });

  final String name;
  final String logo;
  final Color textColor;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevated : const Color(0xFFF0F5F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(6),
          child: logo.trim().isEmpty
              ? _Initial(name: name, color: secondaryText)
              : CachedNetworkImage(
                  imageUrl: logo,
                  fit: BoxFit.contain,
                  memCacheWidth: 180,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => Center(
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: secondaryText.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      _Initial(name: name, color: secondaryText),
                ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isEmpty ? '?' : name.substring(0, 1),
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = isLive ? AppColors.live : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isLive)
            const LivePulseDot(size: 6)
          else
            Icon(Icons.schedule_rounded, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            isLive ? l10n.live : l10n.upcoming,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveLabel extends StatelessWidget {
  const _LiveLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const LivePulseDot(size: 6),
        const SizedBox(width: 5),
        Text(
          context.l10n.liveNow,
          style: const TextStyle(
            color: AppColors.live,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.startTime});

  final DateTime startTime;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = widget.startTime.difference(DateTime.now());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.timer_outlined,
          size: 12,
          color: AppColors.accent,
        ),
        const SizedBox(width: 4),
        Text(
          l10n.startsIn(l10n.formatCountdown(remaining)),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.name, required this.logo});

  final String name;
  final String logo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.04)
            : AppColors.teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(2),
            child: logo.trim().isEmpty
                ? const Icon(
                    Icons.live_tv_rounded,
                    size: 11,
                    color: AppColors.teal,
                  )
                : CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.contain,
                    memCacheWidth: 60,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.live_tv_rounded,
                      size: 11,
                      color: AppColors.teal,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
