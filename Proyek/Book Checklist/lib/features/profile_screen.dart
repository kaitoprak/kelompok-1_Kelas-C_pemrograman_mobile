import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/shelf_widgets.dart';
import '../domain/media_entry.dart';
import '../providers/app_providers.dart';
import '../providers/social_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(mediaEntriesProvider);
    final name = ref.watch(profileNameProvider).asData?.value ?? 'Reader';
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => LoadingFailure(
            message: 'Your profile could not be loaded.',
            onRetry: () => ref.read(mediaEntriesProvider.notifier).refresh(),
          ),
          data: (items) {
            final booksRead = items
                .where(
                  (entry) =>
                      entry.type == MediaType.book &&
                      entry.status == MediaStatus.completed,
                )
                .length;
            final moviesWatched = items
                .where(
                  (entry) =>
                      entry.type == MediaType.movie &&
                      entry.status == MediaStatus.completed,
                )
                .length;
            final seriesDone = items
                .where(
                  (entry) =>
                      entry.type == MediaType.series &&
                      entry.status == MediaStatus.completed,
                )
                .length;
            final completed = items
                .where((entry) => entry.status == MediaStatus.completed)
                .length;
            final active = items
                .where(
                  (entry) =>
                      entry.status == MediaStatus.currentlyReading ||
                      entry.status == MediaStatus.watching,
                )
                .length;
            final ratings = items
                .map((entry) => entry.rating)
                .whereType<double>()
                .toList();
            final average = ratings.isEmpty
                ? null
                : ratings.reduce((a, b) => a + b) / ratings.length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 31,
                          backgroundColor: Theme.of(context).colorScheme.primary
                              .withValues(alpha: .18),
                          child: Text(
                            name.isEmpty
                                ? 'R'
                                : name.characters.first.toUpperCase(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Your reading & watch journal',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editName(context, ref, name),
                          tooltip: 'Edit name',
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeading('Your activity'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatCard(
                      label: 'Books read',
                      value: booksRead,
                      icon: Icons.menu_book_rounded,
                      color: ShelfColors.book,
                    ),
                    const SizedBox(width: 10),
                    StatCard(
                      label: 'Watched',
                      value: moviesWatched,
                      icon: Icons.local_movies_rounded,
                      color: ShelfColors.movie,
                    ),
                    const SizedBox(width: 10),
                    StatCard(
                      label: 'Series done',
                      value: seriesDone,
                      icon: Icons.live_tv_rounded,
                      color: ShelfColors.series,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _ActivityLine(
                          icon: Icons.library_books_outlined,
                          label: 'Items on your shelf',
                          value: '${items.length}',
                        ),
                        const Divider(height: 24),
                        _ActivityLine(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Completed',
                          value: '$completed',
                        ),
                        const Divider(height: 24),
                        _ActivityLine(
                          icon: Icons.timelapse_rounded,
                          label: 'In progress',
                          value: '$active',
                        ),
                        const Divider(height: 24),
                        _ActivityLine(
                          icon: Icons.star_outline_rounded,
                          label: 'Average rating',
                          value: average == null
                              ? '—'
                              : '${average.toStringAsFixed(1)} / 5',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeading('Preferences'),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Appearance',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Dark'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.settings_brightness_outlined),
                              label: Text('System'),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (selection) => ref
                              .read(themeModeProvider.notifier)
                              .set(selection.first),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeading('Your data'),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.ios_share_rounded),
                        title: const Text('Export a backup'),
                        subtitle: const Text('Share a JSON copy of your shelf'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _export(context, items),
                      ),
                      const Divider(height: 1, indent: 56),
                      const ListTile(
                        leading: Icon(Icons.offline_pin_outlined),
                        title: Text('Stored on this device'),
                        subtitle: Text(
                          'Your library works without an internet connection',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Sign out'),
                    onTap: () async {
                      try {
                        final user = ref.read(firebaseAuthProvider).currentUser;
                        if (user != null) {
                          await ref
                              .read(socialPushServiceProvider)
                              .disableForUser(user.uid);
                        }
                        await ref.read(authRepositoryProvider).signOut();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not securely sign out: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    'MyShelf · Your stories, your pace',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      await ref.read(profileNameProvider.notifier).setName(name);
    }
  }

  static Future<void> _export(
    BuildContext context,
    List<MediaEntry> items,
  ) async {
    try {
      final now = DateTime.now();
      final filename =
          'myshelf-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      final content = const JsonEncoder.withIndent('  ').convert({
        'app': 'MyShelf',
        'version': 1,
        'exportedAt': now.toIso8601String(),
        'entries': items.map((entry) => entry.toMap()).toList(),
      });
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(content),
              mimeType: 'application/json',
              name: filename,
            ),
          ],
          subject: 'MyShelf backup',
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup could not be created: $error')),
        );
      }
    }
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 19,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}
