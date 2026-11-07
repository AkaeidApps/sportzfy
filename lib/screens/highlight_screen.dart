import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/highlight_model.dart';
import '../providers/iptv_provider.dart';
import '../routes/app_routes.dart';
import '../screens/player_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/highlight_card.dart';

class HighlightScreen extends ConsumerWidget {
  const HighlightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final highlights = ref.watch(
      iptvProvider.select((state) => state.highlights),
    );
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: 1 + highlights.length + (highlights.isEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.recent,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.matchHighlights,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.highlightsSubtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        if (highlights.isEmpty) {
          return _EmptyHighlights(
            title: l10n.highlightsEmptyTitle,
            subtitle: l10n.highlightsEmptySubtitle,
          );
        }

        final highlight = highlights[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: HighlightCard(
            highlight: highlight,
            onTap: () => _openHighlight(context, highlight),
          ),
        );
      },
    );
  }

  void _openHighlight(BuildContext context, HighlightModel highlight) {
    final l10n = context.l10n;
    context.pushNamed(
      AppRoutes.playerName,
      extra: PlayerArgs(
        title: highlight.titleFor(l10n.language),
        subtitle: '${l10n.sportLabel(highlight.sport)} • ${l10n.highlight}',
        streamUrl: highlight.streamUrl,
        isLive: false,
      ),
    );
  }
}

class _EmptyHighlights extends StatelessWidget {
  const _EmptyHighlights({required this.title, required this.subtitle});

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
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              color: AppColors.teal,
              size: 28,
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
