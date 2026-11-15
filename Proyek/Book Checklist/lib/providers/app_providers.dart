import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../data/media_repository.dart';
import '../domain/media_entry.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.watch(appDatabaseProvider)),
);

final mediaEntriesProvider =
    AsyncNotifierProvider<MediaEntriesController, List<MediaEntry>>(
      MediaEntriesController.new,
    );

class MediaEntriesController extends AsyncNotifier<List<MediaEntry>> {
  @override
  Future<List<MediaEntry>> build() =>
      ref.watch(mediaRepositoryProvider).getAll();

  Future<MediaEntry> save(MediaEntry entry) async {
    final saved = await ref.read(mediaRepositoryProvider).save(entry);
    state = AsyncData(await ref.read(mediaRepositoryProvider).getAll());
    return saved;
  }

  Future<void> delete(int id) async {
    await ref.read(mediaRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(mediaRepositoryProvider).getAll());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(mediaRepositoryProvider).getAll);
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  final _preferences = SharedPreferencesAsync();

  @override
  Future<ThemeMode> build() async =>
      switch (await _preferences.getString(_key)) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  Future<void> set(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await _preferences.setString(_key, value);
    state = AsyncData(mode);
  }
}

final profileNameProvider =
    AsyncNotifierProvider<ProfileNameController, String>(
      ProfileNameController.new,
    );

class ProfileNameController extends AsyncNotifier<String> {
  static const _key = 'profile_name';
  final _preferences = SharedPreferencesAsync();

  @override
  Future<String> build() async =>
      await _preferences.getString(_key) ?? 'Reader';

  Future<void> setName(String value) async {
    final name = value.trim().isEmpty ? 'Reader' : value.trim();
    await _preferences.setString(_key, name);
    state = AsyncData(name);
  }
}
