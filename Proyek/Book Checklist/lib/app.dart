import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'domain/media_entry.dart';
import 'features/edit_entry_screen.dart';
import 'features/entry_detail_screen.dart';
import 'features/home_screen.dart';
import 'features/library_screen.dart';
import 'features/profile_screen.dart';
import 'features/search_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/auth_screen.dart';
import 'providers/app_providers.dart';

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/books',
              builder: (context, state) =>
                  const LibraryScreen(type: MediaType.book),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/movies',
              builder: (context, state) =>
                  const LibraryScreen(type: MediaType.movie),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/series',
              builder: (context, state) =>
                  const LibraryScreen(type: MediaType.series),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/entry/new/:type',
      builder: (context, state) => EditEntryScreen(
        type: MediaType.values.byName(state.pathParameters['type']!),
        entry: state.extra as MediaEntry?,
      ),
    ),
    GoRoute(
      path: '/entry/:id',
      builder: (context, state) =>
          EntryDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
  ],
);

class MyShelfApp extends ConsumerWidget {
  const MyShelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).asData?.value ?? ThemeMode.dark;
    return ref
        .watch(authStateProvider)
        .when(
          loading: () => MaterialApp(
            title: 'MyShelf',
            theme: shelfTheme(Brightness.light),
            darkTheme: shelfTheme(Brightness.dark),
            themeMode: mode,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => MaterialApp(
            title: 'MyShelf',
            theme: shelfTheme(Brightness.light),
            darkTheme: shelfTheme(Brightness.dark),
            themeMode: mode,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not check your sign-in status: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          data: (user) => user == null
              ? MaterialApp(
                  title: 'MyShelf',
                  debugShowCheckedModeBanner: false,
                  theme: shelfTheme(Brightness.light),
                  darkTheme: shelfTheme(Brightness.dark),
                  themeMode: mode,
                  home: const AuthScreen(),
                )
              : MaterialApp.router(
                  title: 'MyShelf',
                  debugShowCheckedModeBanner: false,
                  theme: shelfTheme(Brightness.light),
                  darkTheme: shelfTheme(Brightness.dark),
                  themeMode: mode,
                  routerConfig: _router,
                ),
        );
  }
}
