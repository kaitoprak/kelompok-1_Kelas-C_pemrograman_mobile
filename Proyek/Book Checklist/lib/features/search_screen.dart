import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/shelf_widgets.dart';
import '../domain/media_entry.dart';
import '../providers/app_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  MediaType? _type;
  MediaStatus? _status;
  String? _genre;
  String _query = '';
  bool _ratingFirst = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(mediaEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Search your shelf')),
      body: SafeArea(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => LoadingFailure(
            message: 'Search is unavailable right now.',
            onRetry: () => ref.read(mediaEntriesProvider.notifier).refresh(),
          ),
          data: (entries) {
            final genres =
                entries
                    .map((entry) => entry.genre.trim())
                    .where((genre) => genre.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
            final statuses =
                entries.map((entry) => entry.status).toSet().toList()
                  ..sort((a, b) => a.label.compareTo(b.label));
            final results = entries.where((entry) {
              final query = _query.toLowerCase();
              final matchesText =
                  query.isEmpty ||
                  [
                    entry.title,
                    entry.creator,
                    entry.genre,
                    entry.synopsis,
                    entry.notes,
                  ].any((value) => value.toLowerCase().contains(query));
              return matchesText &&
                  (_type == null || entry.type == _type) &&
                  (_status == null || entry.status == _status) &&
                  (_genre == null || entry.genre == _genre);
            }).toList();
            results.sort(
              (a, b) => _ratingFirst
                  ? (b.rating ?? 0).compareTo(a.rating ?? 0)
                  : b.updatedAt.compareTo(a.updatedAt),
            );
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Title, author, genre, or note',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _TypeChip(
                              label: 'Everything',
                              selected: _type == null,
                              onTap: () => setState(() => _type = null),
                            ),
                            for (final type in MediaType.values)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _TypeChip(
                                  label: type.plural,
                                  selected: _type == type,
                                  onTap: () => setState(
                                    () => _type = _type == type ? null : type,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<MediaStatus>(
                              initialValue: _status,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Any status'),
                                ),
                                ...statuses.map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _status = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _genre,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Genre',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Any genre'),
                                ),
                                ...genres.map(
                                  (genre) => DropdownMenuItem(
                                    value: genre,
                                    child: Text(
                                      genre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _genre = value),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () =>
                                setState(() => _ratingFirst = !_ratingFirst),
                            tooltip: _ratingFirst
                                ? 'Sort by recently updated'
                                : 'Sort by rating',
                            icon: Icon(
                              _ratingFirst
                                  ? Icons.star_rounded
                                  : Icons.schedule_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          children: [
                            EmptyState(
                              title: entries.isEmpty
                                  ? 'Your shelf is waiting'
                                  : 'Nothing came up',
                              message: entries.isEmpty
                                  ? 'Add your first book, film, or series to make it searchable.'
                                  : 'Try a different title or clear one of the filters.',
                              actionLabel: entries.isEmpty
                                  ? 'Add a book'
                                  : 'Clear search',
                              onAction: entries.isEmpty
                                  ? () => context.push('/entry/new/book')
                                  : () {
                                      _controller.clear();
                                      setState(() {
                                        _query = '';
                                        _type = null;
                                        _status = null;
                                        _genre = null;
                                      });
                                    },
                              icon: Icons.manage_search_rounded,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              EntryTile(entry: results[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
