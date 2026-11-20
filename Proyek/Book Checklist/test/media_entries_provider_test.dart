import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_shelf/data/firestore_media_repository.dart';
import 'package:my_shelf/domain/media_entry.dart';
import 'package:my_shelf/providers/app_providers.dart';

void main() {
  test(
    'shows a pending save immediately and rolls it back on failure',
    () async {
      final repository = _InMemoryMediaRepository();
      final completer = Completer<MediaEntry>();
      repository.nextSaveCompleter = completer;
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(mediaEntriesProvider.future);
      final saveFuture = container
          .read(mediaEntriesProvider.notifier)
          .save(_entry());

      final optimistic = container.read(mediaEntriesProvider).requireValue;
      expect(optimistic, hasLength(1));
      expect(optimistic.single.id, 'entry-1');

      completer.completeError(StateError('Firestore unavailable'));
      await expectLater(saveFuture, throwsA(isA<StateError>()));

      expect(container.read(mediaEntriesProvider).requireValue, isEmpty);
    },
  );

  test(
    'save and delete update the shelf without refetching all entries',
    () async {
      final repository = _InMemoryMediaRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(mediaEntriesProvider.future);
      final saved = await container
          .read(mediaEntriesProvider.notifier)
          .save(_entry());

      expect(repository.getAllCalls, 0);
      expect(container.read(mediaEntriesProvider).requireValue, [saved]);

      await container.read(mediaEntriesProvider.notifier).delete(saved.id!);

      expect(repository.getAllCalls, 0);
      expect(container.read(mediaEntriesProvider).requireValue, isEmpty);
    },
  );
}

ProviderContainer _container(_InMemoryMediaRepository repository) =>
    ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        mediaRepositoryProvider.overrideWithValue(repository),
      ],
    );

class _InMemoryMediaRepository implements FirestoreMediaRepository {
  final List<MediaEntry> _entries = [];
  int _nextId = 0;
  int getAllCalls = 0;
  Completer<MediaEntry>? nextSaveCompleter;

  @override
  String newEntryId() => 'entry-${++_nextId}';

  @override
  Future<List<MediaEntry>> getAll() async {
    getAllCalls++;
    return List.unmodifiable(_entries);
  }

  @override
  Future<MediaEntry?> getById(String id) async {
    final matches = _entries.where((entry) => entry.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<MediaEntry> save(MediaEntry entry) async {
    final completer = nextSaveCompleter;
    nextSaveCompleter = null;
    final saved = await (completer?.future ?? Future.value(entry));
    _entries.removeWhere((existing) => existing.id == saved.id);
    _entries.add(saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }
}

MediaEntry _entry() {
  final now = DateTime(2026, 11, 20);
  return MediaEntry(
    type: MediaType.book,
    title: 'The Example Book',
    status: MediaStatus.wantToRead,
    createdAt: now,
    updatedAt: now,
  );
}
