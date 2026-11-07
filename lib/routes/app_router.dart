import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../screens/category_screen.dart';
import '../screens/highlight_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/player_screen.dart';
import '../screens/schedule_screen.dart';
import '../widgets/error_view.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.category,
                name: AppRoutes.categoryName,
                builder: (context, state) => const CategoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.schedule,
                name: AppRoutes.scheduleName,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.highlights,
                name: AppRoutes.highlightsName,
                builder: (context, state) => const HighlightScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.player,
        name: AppRoutes.playerName,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is PlayerArgs
              ? extra
              : PlayerArgs.fromQuery(state.uri.queryParameters);
          return PlayerScreen(args: args);
        },
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = context.l10n;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.appName)),
        body: ErrorView(
          title: l10n.pageNotFound,
          message: l10n.pageNotFoundBody,
          icon: Icons.explore_off_rounded,
          onRetry: () => context.go(AppRoutes.home),
        ),
      );
    },
  );
});
