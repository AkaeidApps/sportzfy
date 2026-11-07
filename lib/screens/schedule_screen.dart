import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/iptv_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/connection_banner.dart';
import '../widgets/error_view.dart';
import '../widgets/match_card.dart';

/// Full upcoming-fixture list, mirroring Sportzfy's Schedule tab.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(iptvProvider);
    final notifier = ref.read(iptvProvider.notifier);
    final upcoming = state.upcomingMatches;

    void showReminder() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.reminderSet)));
    }

    if (state.status == IptvStatus.loading && state.allChannels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.loadingChannels,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == IptvStatus.error &&
        state.allChannels.isEmpty &&
        upcoming.isEmpty) {
      return ErrorView(
        title: _failureTitle(l10n, state),
        message: _failureHint(l10n, state),
        onRetry: notifier.refresh,
        icon: Icons.cloud_off_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.teal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _ScheduleHeader(count: upcoming.length),
          if (state.networkFailed && state.allChannels.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ConnectionBanner(
              message: l10n.cachedBanner,
              icon: Icons.cloud_off_rounded,
              onRetry: notifier.refresh,
            ),
          ],
          const SizedBox(height: 16),
          if (upcoming.isEmpty)
            _EmptySchedule(
              title: l10n.noUpcomingTitle,
              subtitle: l10n.noUpcomingSubtitle,
            )
          else
            for (final match in upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchCard(
                  match: match,
                  onAction: showReminder,
                ),
              ),
        ],
      ),
    );
  }

  static String _failureTitle(AppLocalizations l10n, IptvState state) {
    return switch (state.failure) {
      AppFailureType.server => l10n.serverError,
      AppFailureType.parse => l10n.parseError,
      AppFailureType.unknown => l10n.unknownError,
      _ => l10n.noInternet,
    };
  }

  static String _failureHint(AppLocalizations l10n, IptvState state) {
    return switch (state.failure) {
      AppFailureType.server => l10n.serverErrorHint,
      AppFailureType.parse => l10n.unknownErrorHint,
      AppFailureType.unknown => l10n.unknownErrorHint,
      _ => l10n.noInternetHint,
    };
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A1408), Color(0xFF0B0B12)],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accent,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        l10n.schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.digits(count),
                        style: const TextStyle(
                          color: AppColors.accentSoft,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.scheduleSubtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.4,
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

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.accent,
              size: 27,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
