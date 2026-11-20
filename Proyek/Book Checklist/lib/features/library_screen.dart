import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/shelf_widgets.dart';
import '../domain/media_entry.dart';
import '../providers/app_providers.dart';

enum ShelfSort { recentlyAdded, recentlyUpdated, title, rating, oldest }

extension ShelfSortLabel on ShelfSort {
  String get label => switch (this) {
    ShelfSort.recentlyAdded => 'Recently added',
    ShelfSort.recentlyUpdated => 'Recently updated',
    ShelfSort.title => 'Title A–Z',
    ShelfSort.rating => 'Highest rated',
    ShelfSort.oldest => 'Oldest added',
  };
}

class LibraryFilters {
  const LibraryFilters({
    this.status,
    this.genre,
    this.year,
    this.minimumRating,
    this.sort = ShelfSort.recentlyUpdated,
  });

  final MediaStatus? status;
  final String? genre;
  final int? year;
  final double? minimumRating;
  final ShelfSort sort;

  bool get hasFilters =>
      status != null || genre != null || year != null || minimumRating != null;
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, required this.type});
  final MediaType type;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  LibraryFilters _filters = const LibraryFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<MediaEntry> allItems) async {
    final genres =
        allItems
            .map((entry) => entry.genre.trim())
            .where((genre) => genre.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final years =
        allItems
            .map((entry) => entry.releaseYear)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final filters = await showModalBottomSheet<LibraryFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FilterSheet(
        filters: _filters,
        genres: genres,
        years: years,
        type: widget.type,
      ),
    );
    if (filters != null && mounted) setState(() => _filters = filters);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(mediaEntriesProvider);
    final tint = switch (widget.type) {
      MediaType.book => ShelfColors.book,
      MediaType.movie => ShelfColors.movie,
      MediaType.series => ShelfColors.series,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.plural),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            tooltip: 'Search all',
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 2),
          IconButton.filledTonal(
            onPressed: () => context.push('/entry/new/${widget.type.name}'),
            tooltip: 'Add ${widget.type.label.toLowerCase()}',
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => LoadingFailure(
            message:
                'Your ${widget.type.plural.toLowerCase()} could not be loaded.',
            onRetry: () => ref.read(mediaEntriesProvider.notifier).refresh(),
          ),
          data: (allItems) {
            final library = allItems
                .where((entry) => entry.type == widget.type)
                .toList();
            final filtered = library.where((entry) {
              final matchesQuery =
                  _query.isEmpty ||
                  [entry.title, entry.creator, entry.genre, entry.synopsis].any(
                    (value) =>
                        value.toLowerCase().contains(_query.toLowerCase()),
                  );
              return matchesQuery &&
                  (_filters.status == null ||
                      entry.status == _filters.status) &&
                  (_filters.genre == null || entry.genre == _filters.genre) &&
                  (_filters.year == null ||
                      entry.releaseYear == _filters.year) &&
                  (_filters.minimumRating == null ||
                      (entry.rating ?? 0) >= _filters.minimumRating!);
            }).toList();
            _sort(filtered, _filters.sort);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText:
                              'Search ${widget.type.plural.toLowerCase()}',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _StatusChip(
                              label: 'All',
                              selected: _filters.status == null,
                              onTap: () => setState(
                                () => _filters = LibraryFilters(
                                  genre: _filters.genre,
                                  year: _filters.year,
                                  minimumRating: _filters.minimumRating,
                                  sort: _filters.sort,
                                ),
                              ),
                            ),
                            ...statusesFor(widget.type).map(
                              (status) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _StatusChip(
                                  label: status.label,
                                  selected: _filters.status == status,
                                  onTap: () => setState(
                                    () => _filters = LibraryFilters(
                                      status: _filters.status == status
                                          ? null
                                          : status,
                                      genre: _filters.genre,
                                      year: _filters.year,
                                      minimumRating: _filters.minimumRating,
                                      sort: _filters.sort,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${filtered.length} ${filtered.length == 1 ? 'item' : 'items'}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _openFilters(library),
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _filters.hasFilters ? tint : null,
                            ),
                            label: Text(
                              _filters.hasFilters
                                  ? 'Filters · active'
                                  : 'Filter & sort',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            EmptyState(
                              title: library.isEmpty
                                  ? 'Your ${widget.type.plural.toLowerCase()} shelf is empty'
                                  : 'No matches found',
                              message: library.isEmpty
                                  ? 'Add the stories you love or want to discover.'
                                  : 'Try another search or clear your filters.',
                              actionLabel: library.isEmpty
                                  ? 'Add ${widget.type.label.toLowerCase()}'
                                  : 'Clear filters',
                              onAction: library.isEmpty
                                  ? () => context.push(
                                      '/entry/new/${widget.type.name}',
                                    )
                                  : () {
                                      _searchController.clear();
                                      setState(() {
                                        _query = '';
                                        _filters = const LibraryFilters();
                                      });
                                    },
                              icon: widget.type == MediaType.movie
                                  ? Icons.local_movies_rounded
                                  : widget.type == MediaType.series
                                  ? Icons.live_tv_rounded
                                  : Icons.menu_book_rounded,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              EntryTile(entry: filtered[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _sort(List<MediaEntry> items, ShelfSort sort) {
    switch (sort) {
      case ShelfSort.recentlyAdded:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ShelfSort.recentlyUpdated:
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case ShelfSort.title:
        items.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case ShelfSort.rating:
        items.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case ShelfSort.oldest:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.filters,
    required this.genres,
    required this.years,
    required this.type,
  });
  final LibraryFilters filters;
  final List<String> genres;
  final List<int> years;
  final MediaType type;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late MediaStatus? _status = widget.filters.status;
  late String? _genre = widget.filters.genre;
  late int? _year = widget.filters.year;
  late double? _rating = widget.filters.minimumRating;
  late ShelfSort _sort = widget.filters.sort;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter your shelf',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Text(
              'Genre',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _genre,
              decoration: const InputDecoration(labelText: 'Any genre'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any genre')),
                ...widget.genres.map(
                  (genre) => DropdownMenuItem(value: genre, child: Text(genre)),
                ),
              ],
              onChanged: (value) => setState(() => _genre = value),
            ),
            const SizedBox(height: 14),
            Text(
              'Release year',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _year,
              decoration: const InputDecoration(labelText: 'Any year'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any year')),
                ...widget.years.map(
                  (year) => DropdownMenuItem(value: year, child: Text('$year')),
                ),
              ],
              onChanged: (value) => setState(() => _year = value),
            ),
            const SizedBox(height: 14),
            Text(
              'Minimum rating',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final value in [null, 3.0, 4.0, 5.0])
                  ChoiceChip(
                    label: Text(
                      value == null ? 'Any' : '${value.toInt()}+ stars',
                    ),
                    selected: _rating == value,
                    onSelected: (_) => setState(() => _rating = value),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ShelfSort>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: ShelfSort.values
                  .map(
                    (sort) =>
                        DropdownMenuItem(value: sort, child: Text(sort.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _sort = value);
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _status = null;
                      _genre = null;
                      _year = null;
                      _rating = null;
                      _sort = ShelfSort.recentlyUpdated;
                    }),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      LibraryFilters(
                        status: _status,
                        genre: _genre,
                        year: _year,
                        minimumRating: _rating,
                        sort: _sort,
                      ),
                    ),
                    child: const Text('Apply filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
