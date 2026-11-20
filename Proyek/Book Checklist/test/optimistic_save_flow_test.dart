import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_shelf/data/firestore_media_repository.dart';
import 'package:my_shelf/domain/media_entry.dart';
import 'package:my_shelf/features/edit_entry_screen.dart';
import 'package:my_shelf/providers/app_providers.dart';

void main() {
  testWidgets('returns to the shelf immediately and reports save failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _PendingMediaRepository();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const _ShelfHome()),
        GoRoute(
          path: '/add',
          builder: (_, _) => const EditEntryScreen(type: MediaType.book),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          mediaRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Sample book');
    await tester.tap(find.text('Save to shelf'));
    await tester.pumpAndSettle();

    expect(find.text('Sample book'), findsOneWidget);
    expect(find.text('Saving to your shelf…'), findsOneWidget);

    repository.completer.completeError(StateError('Firestore unavailable'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Sample book'), findsNothing);
    expect(find.textContaining('Could not save'), findsOneWidget);
  });
}

class _ShelfHome extends ConsumerWidget {
  const _ShelfHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(mediaEntriesProvider);
    return Scaffold(
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('$error'),
        data: (items) => ListView(
          children: [
            for (final entry in items) ListTile(title: Text(entry.title)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('open-add'),
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PendingMediaRepository implements FirestoreMediaRepository {
  final completer = Completer<MediaEntry>();

  @override
  String newEntryId() => 'pending-entry';

  @override
  Future<List<MediaEntry>> getAll() async => [];

  @override
  Future<MediaEntry?> getById(String id) async => null;

  @override
  Future<MediaEntry> save(MediaEntry entry) => completer.future;

  @override
  Future<void> delete(String id) async {}
}
