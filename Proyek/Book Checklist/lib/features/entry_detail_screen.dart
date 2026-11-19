import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/media_cover.dart';
import '../core/widgets/shelf_widgets.dart';
import '../domain/media_entry.dart';
import '../providers/app_providers.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(mediaEntriesProvider);
    return entries.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: LoadingFailure(
          message: 'Your shelf could not be opened.',
          onRetry: () => ref.read(mediaEntriesProvider.notifier).refresh(),
        ),
      ),
      data: (items) {
        final matches = items.where((entry) => entry.id == id);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              title: 'This item is gone',
              message: 'It may have been removed from your shelf.',
            ),
          );
        }
        final entry = matches.first;
        return _DetailView(entry: entry);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.entry});

  final MediaEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tint = switch (entry.type) {
      MediaType.book => ShelfColors.book,
      MediaType.movie => ShelfColors.movie,
      MediaType.series => ShelfColors.series,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.type.label),
        actions: [
          IconButton(
            tooltip: 'Edit ${entry.title}',
            onPressed: () =>
                context.push('/entry/new/${entry.type.name}', extra: entry),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'More options',
            onPressed: () => _showMenu(context, ref),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList.list(
                children: [
                  Center(
                    child: MediaCover(
                      type: entry.type,
                      imagePath: entry.imagePath,
                      imageUrl: entry.imageUrl,
                      width: 176,
                      height: 232,
                      borderRadius: 20,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    entry.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.12),
                  ),
                  if (entry.creator.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.creator,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(label: entry.status.label, color: tint),
                      if (entry.genre.isNotEmpty)
                        _Tag(
                          label: entry.genre,
                          color: scheme.onSurfaceVariant,
                        ),
                      if (entry.releaseYear != null)
                        _Tag(
                          label: '${entry.releaseYear}',
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  if (entry.rating != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: ShelfColors.book,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.rating!.toStringAsFixed(entry.rating! % 1 == 0 ? 0 : 1)} / 5',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (entry.type != MediaType.movie)
                    _ProgressCard(entry: entry, tint: tint),
                  if (entry.type != MediaType.movie) const SizedBox(height: 14),
                  if (entry.synopsis.isNotEmpty) ...[
                    _InfoCard(
                      title: 'Synopsis',
                      child: Text(
                        entry.synopsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (entry.notes.isNotEmpty) ...[
                    _InfoCard(
                      title: 'Your notes',
                      child: Text(
                        entry.notes,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _InfoCard(
                    title: 'Details',
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 14,
                      children: [
                        if (entry.type == MediaType.book &&
                            entry.totalPages > 0)
                          _detailValue(
                            context,
                            'Length',
                            '${entry.totalPages} pages',
                          ),
                        if (entry.type == MediaType.movie &&
                            entry.durationMinutes > 0)
                          _detailValue(
                            context,
                            'Runtime',
                            '${entry.durationMinutes} min',
                          ),
                        if (entry.type == MediaType.series &&
                            entry.totalSeasons > 0)
                          _detailValue(
                            context,
                            'Seasons',
                            '${entry.totalSeasons}',
                          ),
                        if (entry.type == MediaType.series &&
                            entry.totalEpisodes > 0)
                          _detailValue(
                            context,
                            'Episodes',
                            '${entry.totalEpisodes}',
                          ),
                        if (entry.startedAt != null)
                          _detailValue(
                            context,
                            'Started',
                            _date(entry.startedAt!),
                          ),
                        if (entry.completedAt != null)
                          _detailValue(
                            context,
                            'Finished',
                            _date(entry.completedAt!),
                          ),
                        _detailValue(context, 'Added', _date(entry.createdAt)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (entry.status != MediaStatus.completed)
                    FilledButton.icon(
                      onPressed: () => _markComplete(context, ref),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        entry.type == MediaType.book
                            ? 'Mark as read'
                            : entry.type == MediaType.movie
                            ? 'Mark as watched'
                            : 'Mark series complete',
                      ),
                    ),
                  if (entry.type != MediaType.movie &&
                      entry.status != MediaStatus.completed) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _updateProgress(context, ref),
                      icon: const Icon(Icons.trending_up_rounded),
                      label: Text(
                        entry.type == MediaType.book
                            ? 'Update pages read'
                            : 'Update episode',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markComplete(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final updated = entry.copyWith(
      status: MediaStatus.completed,
      pagesRead: entry.type == MediaType.book
          ? entry.totalPages
          : entry.pagesRead,
      currentEpisode: entry.type == MediaType.series
          ? entry.totalEpisodes
          : entry.currentEpisode,
      completedAt: now,
      startedAt: entry.startedAt ?? now,
      updatedAt: now,
    );
    await ref.read(mediaEntriesProvider.notifier).save(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Marked as completed')));
    }
  }

  Future<void> _updateProgress(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text:
          '${entry.type == MediaType.book ? entry.pagesRead : entry.currentEpisode}',
    );
    final isBook = entry.type == MediaType.book;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isBook ? 'Pages read' : 'Last episode watched'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: isBook ? 'Page number' : 'Episode number',
            helperText: isBook
                ? 'Out of ${entry.totalPages} pages'
                : 'Out of ${entry.totalEpisodes} episodes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;
    final max = isBook ? entry.totalPages : entry.totalEpisodes;
    if (max > 0 && result > max) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter a value from 0 to $max')));
      return;
    }
    final now = DateTime.now();
    final updated = isBook
        ? entry.copyWith(
            pagesRead: result,
            status: result >= entry.totalPages && entry.totalPages > 0
                ? MediaStatus.completed
                : MediaStatus.currentlyReading,
            completedAt: result >= entry.totalPages && entry.totalPages > 0
                ? now
                : null,
            clearCompletedAt:
                result < entry.totalPages || entry.totalPages == 0,
            startedAt: entry.startedAt ?? now,
            updatedAt: now,
          )
        : entry.copyWith(
            currentEpisode: result,
            status: result >= entry.totalEpisodes && entry.totalEpisodes > 0
                ? MediaStatus.completed
                : MediaStatus.watching,
            completedAt:
                result >= entry.totalEpisodes && entry.totalEpisodes > 0
                ? now
                : null,
            clearCompletedAt:
                result < entry.totalEpisodes || entry.totalEpisodes == 0,
            startedAt: entry.startedAt ?? now,
            updatedAt: now,
          );
    await ref.read(mediaEntriesProvider.notifier).save(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Progress updated')));
    }
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final delete = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit details'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete from shelf',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || delete == null) return;
    if (!delete) {
      context.push('/entry/new/${entry.type.name}', extra: entry);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this item?'),
        content: Text('“${entry.title}” will be removed from your shelf.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || entry.id == null || !context.mounted) return;
    await ref.read(mediaEntriesProvider.notifier).delete(entry.id!);
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from your shelf')));
    }
  }

  static Widget _detailValue(
    BuildContext context,
    String label,
    String value,
  ) => SizedBox(
    width: 124,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(ShelfRadius.pill),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.entry, required this.tint});
  final MediaEntry entry;
  final Color tint;

  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'Your progress',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.progressLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '${(entry.progress * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: tint, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: entry.progress,
            minHeight: 7,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            color: tint,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
