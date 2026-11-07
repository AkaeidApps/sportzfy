import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/channel_model.dart';
import '../theme/app_colors.dart';
import 'pressable.dart';

/// The 2-column channel tile used on the channels screen.
class ChannelCard extends StatelessWidget {
  const ChannelCard({super.key, required this.channel, required this.onTap});

  final Channel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flag = channel.countryFlagEmoji;
    final meta = <String>[
      if (flag.isNotEmpty) flag,
      if (channel.country?.isNotEmpty ?? false) channel.country!.toUpperCase(),
      if (channel.quality?.isNotEmpty ?? false) channel.quality!,
    ].join('  ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[AppColors.darkCard, Color(0xFF0E0E17)]
              : const <Color>[AppColors.white, Color(0xFFF7FBFC)],
        ),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? AppColors.teal.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        semanticsLabel: '${channel.name} • ${l10n.liveSportsChannel}',
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? const <Color>[
                                    Color(0xFF191926),
                                    Color(0xFF0C0C13),
                                  ]
                                : const <Color>[
                                    Color(0xFFF0F6F7),
                                    Color(0xFFE4EEF0),
                                  ],
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.white.withValues(alpha: 0.06)
                                : AppColors.lightBorder,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: _ChannelLogo(channel: channel),
                      ),
                    ),
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              AppColors.teal,
                              AppColors.tealDark,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.onBrand,
                          size: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 7,
                      top: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.live.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            LivePulseDot(size: 5, color: AppColors.white),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                channel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                ),
              ),
              if (meta.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
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

class _ChannelLogo extends StatelessWidget {
  const _ChannelLogo({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    if (!channel.hasLogo) return const _LogoFallback();

    return CachedNetworkImage(
      imageUrl: channel.logo,
      fit: BoxFit.contain,
      memCacheWidth: 360,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.teal,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const _LogoFallback(),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.live_tv_rounded,
          size: 28,
          color: AppColors.teal,
        ),
      ),
    );
  }
}
