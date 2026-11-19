import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../data/media_catalog_service.dart';
import '../data/firestore_media_repository.dart';
import '../domain/media_entry.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final mediaCatalogProvider = Provider<MediaCatalogService>((ref) {
  final service = MediaCatalogService();
  ref.onDispose(service.close);
  return service;
});

final mediaRepositoryProvider = Provider<FirestoreMediaRepository>(
  (ref) => FirestoreMediaRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

final mediaEntriesProvider =
    AsyncNotifierProvider<MediaEntriesController, List<MediaEntry>>(
      MediaEntriesController.new,
    );

class MediaEntriesController extends AsyncNotifier<List<MediaEntry>> {
  @override
  Future<List<MediaEntry>> build() async {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return [];
    return ref.watch(mediaRepositoryProvider).getAll();
  }

  Future<MediaEntry> save(MediaEntry entry) async {
    final saved = await ref.read(mediaRepositoryProvider).save(entry);
    state = AsyncData(await ref.read(mediaRepositoryProvider).getAll());
    return saved;
  }

  Future<void> delete(String id) async {
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
  Future<String> build() async {
    final user = ref.watch(authStateProvider).asData?.value;
    return user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : user?.email?.split('@').first ??
              await _preferences.getString(_key) ??
              'Reader';
  }

  Future<void> setName(String value) async {
    final name = value.trim().isEmpty ? 'Reader' : value.trim();
    await _preferences.setString(_key, name);
    await ref.read(firebaseAuthProvider).currentUser?.updateDisplayName(name);
    state = AsyncData(name);
  }
}
