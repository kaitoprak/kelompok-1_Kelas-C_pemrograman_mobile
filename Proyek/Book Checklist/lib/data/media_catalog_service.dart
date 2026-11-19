import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/media_entry.dart';

class MediaSearchResult {
  const MediaSearchResult({
    required this.title,
    this.externalId,
    this.creator = '',
    this.genre = '',
    this.imageUrl = '',
    this.releaseYear,
    this.totalPages = 0,
    this.durationMinutes = 0,
    this.synopsis = '',
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
  });

  final String title;
  final int? externalId;
  final String creator;
  final String genre;
  final String imageUrl;
  final int? releaseYear;
  final int totalPages;
  final int durationMinutes;
  final String synopsis;
  final int totalSeasons;
  final int totalEpisodes;

  MediaSearchResult copyWith({int? totalSeasons, int? totalEpisodes}) =>
      MediaSearchResult(
        title: title,
        externalId: externalId,
        creator: creator,
        genre: genre,
        imageUrl: imageUrl,
        releaseYear: releaseYear,
        totalPages: totalPages,
        durationMinutes: durationMinutes,
        synopsis: synopsis,
        totalSeasons: totalSeasons ?? this.totalSeasons,
        totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      );
}

class MediaCatalogException implements Exception {
  const MediaCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MediaCatalogService {
  MediaCatalogService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<MediaSearchResult>> search(MediaType type, String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw ArgumentError.value(query, 'query', 'Must not be empty');
    }

    return switch (type) {
      MediaType.book => _searchBooks(trimmedQuery),
      MediaType.movie => _searchMovies(trimmedQuery),
      MediaType.series => _searchSeries(trimmedQuery),
    };
  }

  Future<MediaSearchResult> loadSeriesDetails(MediaSearchResult result) async {
    final id = result.externalId;
    if (id == null) {
      throw ArgumentError.value(result, 'result', 'Series ID is missing');
    }

    final episodes = _objectList(
      await _getJson(Uri.https('api.tvmaze.com', '/shows/$id/episodes')),
    );
    final seasonNumbers = episodes
        .map((episode) => _integer(episode['season']))
        .where((season) => season > 0);

    return result.copyWith(
      totalSeasons: seasonNumbers.fold<int>(
        0,
        (maximum, season) => season > maximum ? season : maximum,
      ),
      totalEpisodes: episodes
          .where((episode) => _integer(episode['season']) > 0)
          .length,
    );
  }

  Future<List<MediaSearchResult>> _searchBooks(String query) async {
    final data = _object(
      await _getJson(
        Uri.https('openlibrary.org', '/search.json', {
          'title': query,
          'limit': '10',
          'fields': 'title,author_name,subject,first_publish_year,number_of_pages_median,cover_i,first_sentence',
        }),
      ),
    );
    return _objectList(data['docs'])
        .map((item) {
          final coverId = _integer(item['cover_i']);
          final firstSentence = _stringList(item['first_sentence']);
          return MediaSearchResult(
            title: _requiredString(item['title'], 'Book title'),
            creator: _stringList(item['author_name']).join(', '),
            genre: _stringList(item['subject']).take(3).join(', '),
            imageUrl: coverId == 0
                ? ''
                : 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
            releaseYear: _integer(item['first_publish_year']) == 0
                ? null
                : _integer(item['first_publish_year']),
            totalPages: _integer(item['number_of_pages_median']),
            synopsis: firstSentence.isEmpty ? '' : firstSentence.first,
          );
        })
        .toList(growable: false);
  }

  Future<List<MediaSearchResult>> _searchMovies(String query) async {
    final data = _object(
      await _getJson(
        Uri.https('en.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'generator': 'search',
          'gsrsearch': '$query film',
          'gsrlimit': '10',
          'prop': 'pageimages|extracts',
          'exintro': '1',
          'explaintext': '1',
          'piprop': 'thumbnail',
          'pithumbsize': '300',
          'format': 'json',
          'redirects': '1',
        }),
      ),
    );
    final pages = data['query'] == null
        ? const <Map<String, Object?>>[]
        : _objectValues(_object(data['query'])['pages']);
    return pages
        .where(
          (page) => _isMoviePage(
            _string(page['title']),
            query,
            _string(page['extract']),
          ),
        )
        .toList()
        .map((item) {
          final title = _string(item['title']);
          final synopsis = _string(item['extract']);
          return MediaSearchResult(
            title: _displayMovieTitle(title),
            creator: _movieDirector(synopsis),
            imageUrl: _secureImageUrl(
              _objectOrEmpty(item['thumbnail'])['source'],
            ),
            releaseYear: _year(synopsis),
            synopsis: synopsis,
          );
        })
        .toList(growable: false);
  }

  Future<List<MediaSearchResult>> _searchSeries(String query) async {
    final data = _objectList(
      await _getJson(
        Uri.https('api.tvmaze.com', '/search/shows', {'q': query}),
      ),
    );
    return data
        .map((item) {
          final show = _object(item['show']);
          final image = show['image'] == null
              ? const <String, Object?>{}
              : _object(show['image']);
          return MediaSearchResult(
            externalId: _requiredInteger(show['id'], 'Series ID'),
            title: _requiredString(show['name'], 'Series title'),
            genre: _stringList(show['genres']).join(', '),
            imageUrl: _secureImageUrl(image['original'] ?? image['medium']),
            releaseYear: _year(show['premiered']),
            durationMinutes: _integer(show['runtime']),
            synopsis: _plainText(_string(show['summary'])),
          );
        })
        .toList(growable: false);
  }

  Future<Object?> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MediaCatalogException(
        'Catalog request failed (${response.statusCode}).',
      );
    }
    return jsonDecode(response.body);
  }

  void close() => _client.close();

  static Map<String, Object?> _object(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('Catalog returned an invalid object.');
  }

  static List<Map<String, Object?>> _objectList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Catalog returned an invalid result list.');
    }
    return value.map(_object).toList(growable: false);
  }

  static List<Map<String, Object?>> _objectValues(Object? value) {
    if (value is! Map) {
      throw const FormatException('Catalog returned an invalid result map.');
    }
    return value.values.map(_object).toList(growable: false);
  }

  static Map<String, Object?> _objectOrEmpty(Object? value) =>
      value == null ? const <String, Object?>{} : _object(value);

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Catalog returned an invalid text list.');
    }
    return value.whereType<String>().toList(growable: false);
  }

  static String _requiredString(Object? value, String field) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('Catalog result is missing $field.');
  }

  static int _requiredInteger(Object? value, String field) {
    if (value is int) return value;
    throw FormatException('Catalog result is missing $field.');
  }

  static String _string(Object? value) => value is String ? value.trim() : '';

  static int _integer(Object? value) => value is num ? value.toInt() : 0;

  static bool _isMoviePage(String title, String query, String synopsis) {
    if (RegExp(
      r'\bmay refer to\b|\bcan refer to\b',
      caseSensitive: false,
    ).hasMatch(synopsis)) {
      return false;
    }
    final cleanTitle = _displayMovieTitle(title);
    final normalizedTitle = cleanTitle.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final normalizedQuery = query.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalizedTitle == normalizedQuery ||
        RegExp(
          r'\(\d{4} film\)|\(film\)',
          caseSensitive: false,
        ).hasMatch(title);
  }

  static String _displayMovieTitle(String title) =>
      title.replaceFirst(RegExp(r'\s+\(film\)$', caseSensitive: false), '');

  static String _movieDirector(String synopsis) {
    final match = RegExp(
      r'\bdirected by ([^,.]+)',
      caseSensitive: false,
    ).firstMatch(synopsis);
    return match?.group(1)?.trim() ?? '';
  }

  static int? _year(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'\b\d{4}\b').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static String _secureImageUrl(Object? value) {
    if (value is! String || value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'http'
        ? uri.replace(scheme: 'https').toString()
        : value;
  }

  static String _plainText(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
