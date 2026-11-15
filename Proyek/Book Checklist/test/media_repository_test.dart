import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;
import 'package:my_shelf/data/app_database.dart';
import 'package:my_shelf/data/media_repository.dart';
import 'package:my_shelf/domain/media_entry.dart';

void main() {
  late Directory directory;
  late AppDatabase appDatabase;
  late MediaRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('myshelf_test_');
    appDatabase = AppDatabase(path: p.join(directory.path, 'test.db'));
    repository = MediaRepository(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    await directory.delete(recursive: true);
  });

  test('creates, reads, updates, and deletes a library item', () async {
    expect(await repository.getAll(), isEmpty);

    final now = DateTime(2026, 5, 1);
    final created = await repository.save(
      MediaEntry(
        type: MediaType.series,
        title: 'Northbound',
        creator: 'A. Writer',
        genre: 'Drama',
        totalSeasons: 2,
        totalEpisodes: 16,
        currentSeason: 1,
        currentEpisode: 4,
        status: MediaStatus.watching,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(created.id, isNotNull);
    expect((await repository.getById(created.id!))?.title, 'Northbound');
    expect(await repository.getAll(), hasLength(1));

    final updated = await repository.save(
      created.copyWith(
        currentEpisode: 6,
        notes: 'Good pacing',
        updatedAt: now.add(const Duration(days: 1)),
      ),
    );
    expect(updated.id, created.id);
    expect((await repository.getById(created.id!))?.currentEpisode, 6);
    expect((await repository.getById(created.id!))?.notes, 'Good pacing');

    await repository.delete(created.id!);
    expect(await repository.getById(created.id!), isNull);
    expect(await repository.getAll(), isEmpty);
  });
}
