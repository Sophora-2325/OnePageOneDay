import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/generate_page.dart';
import '../features/library/library_page.dart';
import '../features/settings/api_config_page.dart';
import '../features/reading_mode/reading_mode_page.dart';
import '../features/review/review_page.dart';
import '../features/settings/settings_page.dart';
import '../features/today/today_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, _) => const TodayPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/library', builder: (_, _) => const LibraryPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/review', builder: (_, _) => const ReviewPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (_, _) => const SettingsPage())]),
      ],
    ),
    GoRoute(
      path: '/listen/:day/:rid',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => ReadingModePage(
        day: int.parse(state.pathParameters['day']!),
        readingId: state.pathParameters['rid']!,
      ),
    ),
    GoRoute(path: '/api', parentNavigatorKey: _rootKey, builder: (_, _) => const ApiConfigPage()),
    GoRoute(
      path: '/tutorial',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => TutorialPage(fromConfig: state.uri.queryParameters['from'] == 'api'),
    ),
    GoRoute(path: '/generate', parentNavigatorKey: _rootKey, builder: (_, _) => const GeneratePage()),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '今日'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '题库'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '复盘'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
