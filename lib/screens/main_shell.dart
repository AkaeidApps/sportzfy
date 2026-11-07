import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../providers/iptv_provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_bottom_nav.dart';

/// Root shell that hosts the dark app bar, drawer and four branch pages.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final isDark = themeMode == ThemeMode.dark;
    final currentIndex = navigationShell.currentIndex;

    return PopScope<Object?>(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
              tooltip: l10n.menu,
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.teal, AppColors.tealDark],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: AppColors.onBrand,
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => _showLanguageSheet(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.teal
                    : AppColors.tealDeep,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(language.isBangla ? 'বাংলা' : 'EN'),
            ),
            IconButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).setDark(!isDark);
              },
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              tooltip: isDark ? l10n.lightMode : l10n.darkMode,
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: Drawer(
          width: 312,
          child: _buildDrawer(context, ref, isDark, language),
        ),
        body: navigationShell,
        bottomNavigationBar: CustomBottomNav(
          currentIndex: currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AppLanguage language,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currentIndex = navigationShell.currentIndex;

    void closeDrawer() => Navigator.of(context).pop();

    void goToTab(int index) {
      closeDrawer();
      navigationShell.goBranch(index);
    }

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF0B0B12), Color(0xFF111827)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -34,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 34,
                bottom: -46,
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              AppColors.teal,
                              AppColors.tealDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.3),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer_rounded,
                          color: AppColors.onBrand,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appTagline,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            children: <Widget>[
              _DrawerNavTile(
                icon: Icons.home_rounded,
                label: l10n.home,
                selected: currentIndex == 0,
                onTap: () => goToTab(0),
              ),
              _DrawerNavTile(
                icon: Icons.grid_view_rounded,
                label: l10n.channels,
                selected: currentIndex == 1,
                onTap: () => goToTab(1),
              ),
              _DrawerNavTile(
                icon: Icons.calendar_month_rounded,
                label: l10n.schedule,
                selected: currentIndex == 2,
                onTap: () => goToTab(2),
              ),
              _DrawerNavTile(
                icon: Icons.play_circle_fill_rounded,
                label: l10n.highlights,
                selected: currentIndex == 3,
                onTap: () => goToTab(3),
              ),
              const SizedBox(height: 8),
              Divider(color: theme.dividerTheme.color),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.teal,
                ),
                title: Text(
                  l10n.theme,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                subtitle: Text(
                  isDark ? l10n.darkMode : l10n.lightMode,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setDark(value);
                  },
                ),
                onTap: () {
                  ref.read(themeModeProvider.notifier).setDark(!isDark);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.teal,
                ),
                title: Text(
                  l10n.languageLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                subtitle: Text(
                  language.isBangla ? l10n.bangla : l10n.english,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    language.isBangla ? 'বাংলা' : 'EN',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                onTap: () {
                  closeDrawer();
                  _showLanguageSheet(context, ref);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.teal,
                ),
                title: Text(
                  l10n.refreshData,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                onTap: () {
                  closeDrawer();
                  ref.read(iptvProvider.notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.refreshing)),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.teal,
                ),
                title: Text(
                  l10n.about,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                onTap: () {
                  closeDrawer();
                  _showAbout(context);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.educationalOnly,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.dataSource,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                  fontSize: 10,
                ),
              ),
              Text(
                l10n.version,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(languageProvider);
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.languageLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _LanguageOption(
                  title: l10n.english,
                  subtitle: 'English',
                  selected: current == AppLanguage.english,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(AppLanguage.english),
                ),
                const SizedBox(height: 8),
                _LanguageOption(
                  title: l10n.bangla,
                  subtitle: 'বাংলা',
                  selected: current == AppLanguage.bangla,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(AppLanguage.bangla),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await ref.read(languageProvider.notifier).setLanguage(selected);
    }
  }

  Future<void> _showAbout(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: <Widget>[
              const Icon(Icons.sports_soccer_rounded, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.aboutTitle)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              l10n.aboutBody,
              style: const TextStyle(fontSize: 13.5, height: 1.7),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.teal.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.teal.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.teal,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: AppColors.teal.withValues(alpha: 0.12),
      selectedColor: AppColors.teal,
      iconColor: Theme.of(context).colorScheme.onSurface,
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      onTap: onTap,
    );
  }
}
