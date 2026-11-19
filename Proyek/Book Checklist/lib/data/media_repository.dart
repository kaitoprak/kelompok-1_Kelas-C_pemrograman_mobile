import 'package:sqflite/sqflite.dart';

import '../domain/media_entry.dart';
import 'app_database.dart';

class MediaRepository {
  MediaRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<MediaEntry>> getAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query('media_entries', orderBy: 'updated_at DESC');
    return rows.map(MediaEntry.fromMap).toList(growable: false);
  }

  Future<MediaEntry?> getById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'media_entries',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
      limit: 1,
    );
    return rows.isEmpty ? null : MediaEntry.fromMap(rows.first);
  }

  Future<MediaEntry> save(MediaEntry entry) async {
    final db = await _appDatabase.database;
    final data = entry.toMap()..remove('id');
    if (entry.id == null) {
      final id = await db.insert('media_entries', data);
      return entry.copyWith(id: id.toString());
    }
    await db.update(
      'media_entries',
      data,
      where: 'id = ?',
      whereArgs: [int.parse(entry.id!)],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return entry;
  }

  Future<void> delete(String id) async {
    final db = await _appDatabase.database;
    await db.delete(
      'media_entries',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }
}
