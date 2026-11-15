import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/shelf_widgets.dart';
import '../domain/media_entry.dart';
import '../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(mediaEntriesProvider);
    final name = ref.watch(profileNameProvider).asData?.value ?? 'Reader';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Scaffold(
      body: SafeArea(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => LoadingFailure(
            message: 'Your shelf could not be loaded.',
            onRetry: () => ref.read(mediaEntriesProvider.notifier).refresh(),
          ),
          data: (items) {
            final books = items
                .where((item) => item.type == MediaType.book)
                .toList();
            final movies = items
                .where((item) => item.type == MediaType.movie)
                .toList();
            final series = items
                .where((item) => item.type == MediaType.series)
                .toList();
            final active = items
                .where(
                  (item) =>
                      item.status == MediaStatus.currentlyReading ||
                      item.status == MediaStatus.watching,
                )
                .toList();
            final completed =
                items
                    .where((item) => item.status == MediaStatus.completed)
                    .toList()
                  ..sort(
                    (a, b) => (b.completedAt ?? b.updatedAt).compareTo(
                      a.completedAt ?? a.updatedAt,
                    ),
                  );
            final recent = [...items]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(mediaEntriesProvider.notifier).refresh(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Text(
                                  'MyShelf',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.4,
                                      ),
                                ),
                                const Spacer(),
                                IconButton.filledTonal(
                                  onPressed: () => context.push('/search'),
                                  tooltip: 'Search your shelf',
                                  icon: const Icon(Icons.search_rounded),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => context.go('/profile'),
                                  tooltip: 'Profile and settings',
                                  icon: const Icon(
                                    Icons.account_circle_outlined,
                                    size: 27,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Text(
                              '$greeting, $name',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'A little progress adds up to a lot of stories.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 22),
                            _ShelfHero(
                              total: items.length,
                              active: active.length,
                              onSearch: () => context.push('/search'),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                StatCard(
                                  label: 'Books read',
                                  value: books
                                      .where(
                                        (e) =>
                                            e.status == MediaStatus.completed,
                                      )
                                      .length,
                                  icon: Icons.menu_book_rounded,
                                  color: ShelfColors.book,
                                ),
                                const SizedBox(width: 10),
                                StatCard(
                                  label: 'Watched',
                                  value: movies
                                      .where(
                                        (e) =>
                                            e.status == MediaStatus.completed,
                                      )
                                      .length,
                                  icon: Icons.local_movies_rounded,
                                  color: ShelfColors.movie,
                                ),
                                const SizedBox(width: 10),
                                StatCard(
                                  label: 'Series done',
                                  value: series
                                      .where(
                                        (e) =>
                                            e.status == MediaStatus.completed,
                                      )
                                      .length,
                                  icon: Icons.live_tv_rounded,
                                  color: ShelfColors.series,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: .13),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.timelapse_rounded,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'In progress',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${active.length}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const SectionHeading('Quick add'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _QuickAdd(
                                  type: MediaType.book,
                                  icon: Icons.menu_book_rounded,
                                  tint: ShelfColors.book,
                                  onTap: () => context.push('/entry/new/book'),
                                ),
                                const SizedBox(width: 10),
                                _QuickAdd(
                                  type: MediaType.movie,
                                  icon: Icons.local_movies_rounded,
                                  tint: ShelfColors.movie,
                                  onTap: () => context.push('/entry/new/movie'),
                                ),
                                const SizedBox(width: 10),
                                _QuickAdd(
                                  type: MediaType.series,
                                  icon: Icons.live_tv_rounded,
                                  tint: ShelfColors.series,
                                  onTap: () =>
                                      context.push('/entry/new/series'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            SectionHeading(
                              'In progress',
                              actionLabel: active.isNotEmpty ? 'See all' : null,
                              onAction: () => context.push('/search'),
                            ),
                            const SizedBox(height: 10),
                            if (active.isEmpty)
                              EmptyState(
                                title: 'Nothing in progress yet',
                                message: 'Add a book, film, or series and pick up where you left off.',
                                actionLabel: 'Add something',
                                onAction: () => context.push('/entry/new/book'),
                                icon: Icons.timelapse_rounded,
                              )
                            else
                              ...active
                                  .take(3)
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: EntryTile(
                                        entry: entry,
                                        compact: true,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 20),
                            SectionHeading(
                              'Recently added',
                              actionLabel: recent.isNotEmpty ? 'Browse' : null,
                              onAction: () => context.push('/search'),
                            ),
                            const SizedBox(height: 10),
                            if (recent.isEmpty)
                              EmptyState(
                                title: 'Your shelf starts here',
                                message: 'Keep the books you want to read and the stories you want to remember in one place.',
                                actionLabel: 'Add your first item',
                                onAction: () => context.push('/entry/new/book'),
                              )
                            else
                              ...recent
                                  .take(3)
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: EntryTile(
                                        entry: entry,
                                        compact: true,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 20),
                            SectionHeading(
                              'Recently completed',
                              actionLabel: completed.isNotEmpty
                                  ? 'Search history'
                                  : null,
                              onAction: () => context.push('/search'),
                            ),
                            const SizedBox(height: 10),
                            if (completed.isEmpty)
                              const EmptyState(
                                title: 'Every finish is worth remembering',
                                message: 'Completed books, films, and series will collect here.',
                                icon: Icons.check_circle_outline_rounded,
                              )
                            else
                              ...completed
                                  .take(3)
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: EntryTile(
                                        entry: entry,
                                        compact: true,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShelfHero extends StatelessWidget {
  const _ShelfHero({
    required this.total,
    required this.active,
    required this.onSearch,
  });
  final int total;
  final int active;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showIllustration = constraints.maxWidth >= 360;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF26342D), Color(0xFF1B2420)]
                  : const [Color(0xFFE2EEE5), Color(0xFFD9E6DC)],
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PERSONAL LIBRARY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.25,
                        fontWeight: FontWeight.w800,
                        color: dark
                            ? ShelfColors.sage
                            : const Color(0xFF42694F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      total == 0
                          ? 'Make room for\nyour next story.'
                          : 'Your stories,\nall in one place.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.06,
                            letterSpacing: -.4,
                          ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      total == 0
                          ? 'Start a shelf that feels like yours.'
                          : '$total saved · $active in progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Explore shelf'),
                    ),
                  ],
                ),
              ),
              if (showIllustration) const SizedBox(width: 8),
              if (showIllustration)
                SizedBox(
                  width: 86,
                  height: 116,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -.18,
                        child: _BookSpine(
                          color: const Color(0xFFB6C9BC),
                          height: 93,
                          width: 53,
                        ),
                      ),
                      Transform.rotate(
                        angle: .13,
                        child: _BookSpine(
                          color: const Color(0xFFD6B98D),
                          height: 108,
                          width: 58,
                        ),
                      ),
                      Transform.rotate(
                        angle: .39,
                        child: _BookSpine(
                          color: const Color(0xFF9DB7A5),
                          height: 82,
                          width: 50,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BookSpine extends StatelessWidget {
  const _BookSpine({
    required this.color,
    required this.height,
    required this.width,
  });
  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: Colors.white.withValues(alpha: .22)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 16,
          offset: const Offset(4, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 2,
          height: height - 20,
          color: Colors.white.withValues(alpha: .22),
        ),
      ),
    ),
  );
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({
    required this.type,
    required this.icon,
    required this.tint,
    required this.onTap,
  });
  final MediaType type;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                type.label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Add new',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
