enum MediaType { book, movie, series }

extension MediaTypeLabel on MediaType {
  String get label => switch (this) {
    MediaType.book => 'Book',
    MediaType.movie => 'Movie',
    MediaType.series => 'Series',
  };

  String get plural => switch (this) {
    MediaType.book => 'Books',
    MediaType.movie => 'Movies',
    MediaType.series => 'Series',
  };

  String get path => name;
}

enum MediaStatus {
  wantToRead,
  currentlyReading,
  wantToWatch,
  watching,
  completed,
  paused,
  onHold,
  dropped,
}

extension MediaStatusLabel on MediaStatus {
  String get label => switch (this) {
    MediaStatus.wantToRead => 'Want to read',
    MediaStatus.currentlyReading => 'Currently reading',
    MediaStatus.wantToWatch => 'Want to watch',
    MediaStatus.watching => 'Watching',
    MediaStatus.completed => 'Completed',
    MediaStatus.paused => 'Paused',
    MediaStatus.onHold => 'On hold',
    MediaStatus.dropped => 'Dropped',
  };
}

List<MediaStatus> statusesFor(MediaType type) => switch (type) {
  MediaType.book => [
    MediaStatus.wantToRead,
    MediaStatus.currentlyReading,
    MediaStatus.completed,
    MediaStatus.paused,
    MediaStatus.dropped,
  ],
  MediaType.movie || MediaType.series => [
    MediaStatus.wantToWatch,
    MediaStatus.watching,
    MediaStatus.completed,
    if (type == MediaType.series) MediaStatus.onHold,
    MediaStatus.dropped,
  ],
};

class MediaEntry {
  const MediaEntry({
    this.id,
    required this.type,
    required this.title,
    required this.status,
    this.creator = '',
    this.imagePath,
    this.imageUrl = '',
    this.genre = '',
    this.releaseYear,
    this.totalPages = 0,
    this.pagesRead = 0,
    this.durationMinutes = 0,
    this.synopsis = '',
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.currentSeason = 1,
    this.currentEpisode = 0,
    this.rating,
    this.notes = '',
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final MediaType type;
  final String title;
  final String creator;
  final String? imagePath;
  final String imageUrl;
  final String genre;
  final int? releaseYear;
  final int totalPages;
  final int pagesRead;
  final int durationMinutes;
  final String synopsis;
  final int totalSeasons;
  final int totalEpisodes;
  final int currentSeason;
  final int currentEpisode;
  final MediaStatus status;
  final double? rating;
  final String notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (status == MediaStatus.completed) return 1;
    if (type == MediaType.book && totalPages > 0) {
      return (pagesRead / totalPages).clamp(0.0, 1.0);
    }
    if (type == MediaType.series && totalEpisodes > 0) {
      return (currentEpisode / totalEpisodes).clamp(0.0, 1.0);
    }
    return 0;
  }

  String get progressLabel => switch (type) {
    MediaType.book => '$pagesRead of $totalPages pages',
    MediaType.series =>
      'S$currentSeason · $currentEpisode of $totalEpisodes eps',
    MediaType.movie =>
      status == MediaStatus.completed ? 'Watched' : 'Not watched yet',
  };

  MediaEntry copyWith({
    String? id,
    MediaType? type,
    String? title,
    String? creator,
    String? imagePath,
    bool clearImagePath = false,
    String? imageUrl,
    String? genre,
    int? releaseYear,
    int? totalPages,
    int? pagesRead,
    int? durationMinutes,
    String? synopsis,
    int? totalSeasons,
    int? totalEpisodes,
    int? currentSeason,
    int? currentEpisode,
    MediaStatus? status,
    double? rating,
    bool clearRating = false,
    String? notes,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MediaEntry(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    creator: creator ?? this.creator,
    imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    genre: genre ?? this.genre,
    releaseYear: releaseYear ?? this.releaseYear,
    totalPages: totalPages ?? this.totalPages,
    pagesRead: pagesRead ?? this.pagesRead,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    synopsis: synopsis ?? this.synopsis,
    totalSeasons: totalSeasons ?? this.totalSeasons,
    totalEpisodes: totalEpisodes ?? this.totalEpisodes,
    currentSeason: currentSeason ?? this.currentSeason,
    currentEpisode: currentEpisode ?? this.currentEpisode,
    status: status ?? this.status,
    rating: clearRating ? null : rating ?? this.rating,
    notes: notes ?? this.notes,
    startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'creator': creator,
    'image_path': imagePath,
    'image_url': imageUrl,
    'genre': genre,
    'release_year': releaseYear,
    'total_pages': totalPages,
    'pages_read': pagesRead,
    'duration_minutes': durationMinutes,
    'synopsis': synopsis,
    'total_seasons': totalSeasons,
    'total_episodes': totalEpisodes,
    'current_season': currentSeason,
    'current_episode': currentEpisode,
    'status': status.name,
    'rating': rating,
    'notes': notes,
    'started_at': startedAt?.millisecondsSinceEpoch,
    'completed_at': completedAt?.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory MediaEntry.fromMap(Map<String, Object?> map) => MediaEntry(
    id: map['id']?.toString(),
    type: MediaType.values.byName(map['type']! as String),
    title: map['title']! as String,
    creator: map['creator'] as String? ?? '',
    imagePath: map['image_path'] as String?,
    imageUrl: map['image_url'] as String? ?? '',
    genre: map['genre'] as String? ?? '',
    releaseYear: map['release_year'] as int?,
    totalPages: map['total_pages'] as int? ?? 0,
    pagesRead: map['pages_read'] as int? ?? 0,
    durationMinutes: map['duration_minutes'] as int? ?? 0,
    synopsis: map['synopsis'] as String? ?? '',
    totalSeasons: map['total_seasons'] as int? ?? 0,
    totalEpisodes: map['total_episodes'] as int? ?? 0,
    currentSeason: map['current_season'] as int? ?? 1,
    currentEpisode: map['current_episode'] as int? ?? 0,
    status: MediaStatus.values.byName(map['status']! as String),
    rating: (map['rating'] as num?)?.toDouble(),
    notes: map['notes'] as String? ?? '',
    startedAt: _date(map['started_at']),
    completedAt: _date(map['completed_at']),
    createdAt: _date(map['created_at']) ?? DateTime.now(),
    updatedAt: _date(map['updated_at']) ?? DateTime.now(),
  );

  static DateTime? _date(Object? value) => value is int
      ? DateTime.fromMillisecondsSinceEpoch(value)
      : value is String
      ? DateTime.tryParse(value)
      : null;
}
