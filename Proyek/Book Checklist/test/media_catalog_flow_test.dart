import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_shelf/data/media_catalog_service.dart';
import 'package:my_shelf/domain/media_entry.dart';
import 'package:my_shelf/features/edit_entry_screen.dart';
import 'package:my_shelf/providers/app_providers.dart';

void main() {
  testWidgets(
    'typing a title shows catalog suggestions and fills selected metadata',
    (tester) async {
      var requestCount = 0;
      final service = MediaCatalogService(
        client: MockClient((_) async {
          requestCount++;
          return http.Response(
            jsonEncode({
              'docs': [
                {
                  'title': 'Dune',
                  'author_name': ['Frank Herbert'],
                  'subject': ['Science Fiction'],
                  'first_publish_year': 1965,
                  'number_of_pages_median': 896,
                  'first_sentence': ['A desert planet.'],
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [mediaCatalogProvider.overrideWithValue(service)],
          child: const MaterialApp(home: EditEntryScreen(type: MediaType.book)),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Dune');
      await tester.pump(const Duration(milliseconds: 400));
      expect(requestCount, 0);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(requestCount, 1);
      expect(find.text('Suggestions'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Dune'));
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(fields.first.controller!.text, 'Dune');
      expect(fields.elementAt(1).controller!.text, 'Frank Herbert');
      expect(fields.elementAt(2).controller!.text, 'Science Fiction');
      expect(fields.elementAt(3).controller!.text, '1965');
    },
  );
}
