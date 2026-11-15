import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({this.path});

  final String? path;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = kIsWeb
        ? 'myshelf.db'
        : path ?? p.join(await getDatabasesPath(), 'myshelf.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE media_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            creator TEXT NOT NULL DEFAULT '',
            image_path TEXT,
            image_url TEXT NOT NULL DEFAULT '',
            genre TEXT NOT NULL DEFAULT '',
            release_year INTEGER,
            total_pages INTEGER NOT NULL DEFAULT 0,
            pages_read INTEGER NOT NULL DEFAULT 0,
            duration_minutes INTEGER NOT NULL DEFAULT 0,
            synopsis TEXT NOT NULL DEFAULT '',
            total_seasons INTEGER NOT NULL DEFAULT 0,
            total_episodes INTEGER NOT NULL DEFAULT 0,
            current_season INTEGER NOT NULL DEFAULT 1,
            current_episode INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            rating REAL,
            notes TEXT NOT NULL DEFAULT '',
            started_at INTEGER,
            completed_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX media_type_updated ON media_entries(type, updated_at DESC)',
        );
      },
    );
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
