import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/channel_model.dart';
import '../providers/iptv_provider.dart';
import '../routes/app_routes.dart';
import '../screens/player_screen.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/channel_card.dart';
import '../widgets/connection_banner.dart';
import '../widgets/error_view.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(iptvProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(iptvProvider.notifier).clearFilters();
    FocusScope.of(context).unfocus();
  }

  void _openChannel(Channel channel) {
    context.pushNamed(
      AppRoutes.playerName,
      extra: PlayerArgs.fromChannel(channel, l10n: context.l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(iptvProvider);
    final notifier = ref.read(iptvProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.close_rounded, size: 19),
                      tooltip: l10n.clearFilters,
                    )
                  : null,
            ),
          ),
        ),
        if (state.sportFilters.length > 1)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.sportFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = state.sportFilters[index];
                final selected = state.selectedSport == filter;
                return ChoiceChip(
                  label: Text(l10n.sportLabel(filter)),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => notifier.setSportFilter(filter),
                  selectedColor: AppColors.teal,
                  backgroundColor: isDark
                      ? AppColors.darkCard
                      : theme.colorScheme.surface,
                  side: BorderSide(
                    color: selected
                        ? AppColors.teal
                        : isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.onBrand
                        : theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        if (state.isRefreshing)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ),
        if (state.networkFailed && state.allChannels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ConnectionBanner(
              message: l10n.cachedBanner,
              icon: Icons.cloud_off_rounded,
              onRetry: notifier.refresh,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
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
                  state.status == IptvStatus.success
                      ? l10n.channelCount(state.channels.length)
                      : l10n.filterChannels,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.clearFilters,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _buildContent(context, state, notifier)),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    IptvState state,
    IptvNotifier notifier,
  ) {
    final l10n = context.l10n;

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
              const SizedBox(height: 6),
              Text(
                l10n.loadingChannelsHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == IptvStatus.error && state.allChannels.isEmpty) {
      return ErrorView(
        title: _failureTitle(l10n, state),
        message: _failureHint(l10n, state),
        onRetry: notifier.refresh,
      );
    }

    if (state.channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.search_off_rounded,
                size: 52,
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.55),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.noChannelTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.noChannelSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (state.hasActiveFilters) ...<Widget>[
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _clearFilters,
                  child: Text(l10n.clearFilters),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.teal,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.84,
        ),
        itemCount: state.channels.length,
        itemBuilder: (context, index) {
          final channel = state.channels[index];
          return ChannelCard(
            channel: channel,
            onTap: () => _openChannel(channel),
          );
        },
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
