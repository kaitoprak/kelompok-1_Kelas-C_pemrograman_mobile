import 'package:flutter_test/flutter_test.dart';
import 'package:my_shelf/domain/media_entry.dart';

void main() {
  group('MediaEntry progress', () {
    test('calculates book progress from pages read', () {
      final entry = _entry(
        type: MediaType.book,
        pagesRead: 45,
        totalPages: 180,
      );
      expect(entry.progress, 0.25);
      expect(entry.progressLabel, '45 of 180 pages');
    });

    test('calculates series progress from episodes watched', () {
      final entry = _entry(
        type: MediaType.series,
        currentEpisode: 24,
        totalEpisodes: 60,
      );
      expect(entry.progress, 0.4);
    });

    test('completed titles always report full progress', () {
      final entry = _entry(
        type: MediaType.movie,
        status: MediaStatus.completed,
      );
      expect(entry.progress, 1);
    });

    test('progress is clamped when counts exceed the total', () {
      final entry = _entry(
        type: MediaType.book,
        pagesRead: 400,
        totalPages: 180,
      );
      expect(entry.progress, 1);
    });
  });

  test('persists all media metadata through the database map format', () {
    final original = _entry(
      type: MediaType.book,
      title: 'The Long Way Home',
      pagesRead: 81,
      totalPages: 320,
      status: MediaStatus.currentlyReading,
      rating: 4.5,
      genre: 'Fantasy',
      startedAt: DateTime(2026, 2, 3),
    );

    final restored = MediaEntry.fromMap(original.toMap());

    expect(restored.title, original.title);
    expect(restored.type, original.type);
    expect(restored.status, original.status);
    expect(restored.pagesRead, 81);
    expect(restored.totalPages, 320);
    expect(restored.rating, 4.5);
    expect(restored.genre, 'Fantasy');
    expect(restored.startedAt, DateTime(2026, 2, 3));
  });
}

MediaEntry _entry({
  MediaType type = MediaType.book,
  String title = 'Sample',
  MediaStatus status = MediaStatus.currentlyReading,
  int pagesRead = 0,
  int totalPages = 0,
  int currentEpisode = 0,
  int totalEpisodes = 0,
  double? rating,
  String genre = '',
  DateTime? startedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return MediaEntry(
    type: type,
    title: title,
    status: status,
    pagesRead: pagesRead,
    totalPages: totalPages,
    currentEpisode: currentEpisode,
    totalEpisodes: totalEpisodes,
    rating: rating,
    genre: genre,
    startedAt: startedAt,
    createdAt: now,
    updatedAt: now,
  );
}
