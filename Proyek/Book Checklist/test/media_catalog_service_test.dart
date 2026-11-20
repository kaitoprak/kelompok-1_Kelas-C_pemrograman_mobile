import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_shelf/data/media_catalog_service.dart';
import 'package:my_shelf/domain/media_entry.dart';

void main() {
  group('MediaCatalogService', () {
    test('maps book search results into entry metadata', () async {
      final service = MediaCatalogService(
        client: MockClient((request) async {
          expect(request.url.host, 'openlibrary.org');
          expect(request.url.queryParameters['title'], 'Dune');
          return http.Response(
            jsonEncode({
              'docs': [
                {
                  'title': 'Dune',
                  'author_name': ['Frank Herbert'],
                  'subject': ['Fiction', 'Science Fiction'],
                  'first_publish_year': 1965,
                  'number_of_pages_median': 896,
                  'first_sentence': ['A desert planet.'],
                  'cover_i': 123,
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final results = await service.search(MediaType.book, 'Dune');

      expect(results, hasLength(1));
      expect(results.single.title, 'Dune');
      expect(results.single.creator, 'Frank Herbert');
      expect(results.single.genre, 'Fiction, Science Fiction');
      expect(results.single.releaseYear, 1965);
      expect(results.single.totalPages, 896);
      expect(
        results.single.imageUrl,
        'https://covers.openlibrary.org/b/id/123-M.jpg',
      );
    });

    test('maps movie search results', () async {
      final service = MediaCatalogService(
        client: MockClient((request) async {
          expect(request.url.host, 'en.wikipedia.org');
          expect(request.url.queryParameters['gsrsearch'], 'Arrival film');
          expect(request.url.queryParameters['origin'], '*');
          return http.Response(
            jsonEncode({
              'query': {
                'pages': {
                  '42': {
                    'pageid': 42,
                    'title': 'Arrival (film)',
                    'extract': 'Arrival is a 2016 science fiction film directed by Denis Villeneuve.',
                    'thumbnail': {'source': 'http://movies.example/poster'},
                  },
                  '43': {
                    'pageid': 43,
                    'title': 'Arrival',
                    'extract': 'Arrival(s) may refer to:',
                  },
                },
              },
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final result = (await service.search(MediaType.movie, 'Arrival')).single;

      expect(result.title, 'Arrival');
      expect(result.creator, 'Denis Villeneuve');
      expect(result.releaseYear, 2016);
      expect(result.imageUrl, 'https://movies.example/poster');
      expect(result.synopsis, contains('science fiction film'));
    });

    test('loads series season and episode counts from TVmaze', () async {
      final service = MediaCatalogService(
        client: MockClient((request) async {
          if (request.url.path == '/search/shows') {
            return http.Response(
              jsonEncode([
                {
                  'show': {
                    'id': 42,
                    'name': 'Example Show',
                    'genres': ['Drama'],
                    'premiered': '2020-01-01',
                    'runtime': 45,
                    'summary': '<p>Stories &amp; people.</p>',
                    'image': {'medium': 'https://shows.example/poster'},
                  },
                },
              ]),
              200,
            );
          }
          expect(request.url.path, '/shows/42/episodes');
          return http.Response(
            jsonEncode([
              {'season': 1},
              {'season': 1},
              {'season': 2},
              {'season': 2},
              {'season': 0},
            ]),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final searchResult = (await service.search(
        MediaType.series,
        'Example Show',
      )).single;
      final result = await service.loadSeriesDetails(searchResult);

      expect(searchResult.title, 'Example Show');
      expect(searchResult.synopsis, 'Stories & people.');
      expect(result.totalSeasons, 2);
      expect(result.totalEpisodes, 4);
    });

    test('reports catalog HTTP errors', () async {
      final service = MediaCatalogService(
        client: MockClient((_) async => http.Response('Unavailable', 503)),
      );
      addTearDown(service.close);

      await expectLater(
        service.search(MediaType.book, 'Dune'),
        throwsA(isA<MediaCatalogException>()),
      );
    });
  });
}
