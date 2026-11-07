import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// The four-tab bottom navigation bar (Live, Channels, Schedule, Highlights).
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final background =
        theme.bottomNavigationBarTheme.backgroundColor ??
        theme.colorScheme.surface;
    final borderColor =
        theme.dividerTheme.color ??
        theme.colorScheme.outline.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 68 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.15;
            return BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.teal,
              unselectedItemColor:
                  theme.bottomNavigationBarTheme.unselectedItemColor,
              selectedFontSize: compact ? 10 : 11,
              unselectedFontSize: compact ? 9 : 10.5,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: l10n.home,
              tooltip: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view_rounded),
              label: l10n.channels,
              tooltip: l10n.channels,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month_rounded),
              label: l10n.schedule,
              tooltip: l10n.schedule,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.play_circle_outline_rounded),
              activeIcon: const Icon(Icons.play_circle_fill_rounded),
              label: l10n.highlights,
              tooltip: l10n.highlights,
            ),
              ],
            );
          },
        ),
      ),
    );
  }
}
