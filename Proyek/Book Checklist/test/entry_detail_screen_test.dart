import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_shelf/domain/media_entry.dart';
import 'package:my_shelf/features/entry_detail_screen.dart';
import 'package:my_shelf/providers/app_providers.dart';

void main() {
  testWidgets('shows an error when marking an entry complete fails', (
    tester,
  ) async {
    final controller = _FailingMediaEntriesController();
    await _pumpDetailScreen(tester, controller);

    await tester.scrollUntilVisible(find.text('Mark series complete'), 300);
    await tester.tap(find.text('Mark series complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Could not mark item as complete'),
      findsOneWidget,
    );
    expect(controller.savedEntry?.status, MediaStatus.completed);
    expect(controller.savedEntry?.currentSeason, 3);
  });

  testWidgets('shows an error when updating progress fails', (tester) async {
    await _pumpDetailScreen(tester, _FailingMediaEntriesController());

    await tester.scrollUntilVisible(find.text('Update episode'), 300);
    await tester.tap(find.text('Update episode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Could not update progress'), findsOneWidget);
  });

  testWidgets('shows an error when removing an entry fails', (tester) async {
    await _pumpDetailScreen(tester, _FailingMediaEntriesController());

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete from shelf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Could not remove item from your shelf'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpDetailScreen(
  WidgetTester tester,
  _FailingMediaEntriesController controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mediaEntriesProvider.overrideWith(() => controller)],
      child: const MaterialApp(home: EntryDetailScreen(id: 'entry-1')),
    ),
  );
  await tester.pumpAndSettle();
}

class _FailingMediaEntriesController extends MediaEntriesController {
  MediaEntry? savedEntry;

  @override
  Future<List<MediaEntry>> build() async => [
    MediaEntry(
      id: 'entry-1',
      type: MediaType.series,
      title: 'Sample series',
      status: MediaStatus.watching,
      totalSeasons: 3,
      totalEpisodes: 24,
      currentSeason: 1,
      currentEpisode: 8,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  Future<MediaEntry> save(MediaEntry entry) async {
    savedEntry = entry;
    throw StateError('Firestore unavailable');
  }

  @override
  Future<void> delete(String id) async {
    throw StateError('Firestore unavailable');
  }
}
