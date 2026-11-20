import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/social_models.dart';
import '../../providers/social_providers.dart';
import '../../core/widgets/rating_stars.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({super.key, required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/community/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      post.authorUsername.isEmpty
                          ? 'R'
                          : post.authorUsername[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          context.push('/community/profile/${post.authorId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '@${post.authorUsername} · ${_formatDate(post.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (post.visibility == 'followers')
                    Tooltip(
                      message: 'Visible to followers',
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (post.text.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(post.text, style: theme.textTheme.bodyLarge),
              ],
              if (post.mediaTitle.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(_mediaIcon(post.mediaType)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.mediaType.isEmpty
                                  ? 'Media'
                                  : _capitalize(post.mediaType),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              post.mediaTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (post.kind == SocialPostKind.rating &&
                  post.rating != null) ...[
                const SizedBox(height: 8),
                RatingStars(rating: post.rating, iconSize: 20, showValue: true),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Discuss',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  static String _capitalize(String value) =>
      value[0].toUpperCase() + value.substring(1);

  static IconData _mediaIcon(String type) => switch (type) {
    'book' => Icons.menu_book_rounded,
    'movie' => Icons.movie_outlined,
    'series' => Icons.live_tv_rounded,
    _ => Icons.auto_stories_rounded,
  };
}

class ComposePostSheet extends ConsumerStatefulWidget {
  const ComposePostSheet({super.key, required this.profile});

  final SocialProfile profile;

  @override
  ConsumerState<ComposePostSheet> createState() => _ComposePostSheetState();
}

class _ComposePostSheetState extends ConsumerState<ComposePostSheet> {
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  SocialPostKind _kind = SocialPostKind.post;
  String _mediaType = '';
  double? _rating;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(socialRepositoryProvider)
          .createPost(
            author: widget.profile,
            kind: _kind,
            text: _textController.text,
            mediaTitle: _titleController.text,
            mediaType: _mediaType,
            rating: _kind == SocialPostKind.rating ? _rating : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not publish: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share with the community',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<SocialPostKind>(
                segments: const [
                  ButtonSegment(
                    value: SocialPostKind.post,
                    label: Text('Post'),
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  ButtonSegment(
                    value: SocialPostKind.rating,
                    label: Text('Rating'),
                    icon: Icon(Icons.star_outline_rounded),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() => _kind = selection.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLength: 1000,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What did you think?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Book, movie, or series (optional)',
                  prefixIcon: Icon(Icons.auto_stories_outlined),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _mediaType,
                decoration: const InputDecoration(labelText: 'Media type'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Not specified')),
                  DropdownMenuItem(value: 'book', child: Text('Book')),
                  DropdownMenuItem(value: 'movie', child: Text('Movie')),
                  DropdownMenuItem(value: 'series', child: Text('Series')),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _mediaType = value ?? ''),
              ),
              if (_kind == SocialPostKind.rating) ...[
                const SizedBox(height: 10),
                RatingStars(
                  rating: _rating,
                  onChanged: (value) => setState(() => _rating = value),
                  showValue: true,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Publishing...' : 'Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowRequestTile extends ConsumerWidget {
  const FollowRequestTile({super.key, required this.follow});

  final SocialFollow follow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(socialProfileProvider(follow.followerId));
    return profile.when(
      loading: () => const ListTile(
        leading: CircleAvatar(child: Icon(Icons.person_outline_rounded)),
        title: Text('Loading request...'),
      ),
      error: (error, stack) => ListTile(
        title: const Text('A follow request could not be loaded.'),
        subtitle: Text('$error'),
      ),
      data: (value) {
        if (value == null) return const SizedBox.shrink();
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person_outline_rounded),
          ),
          title: Text(value.displayName),
          subtitle: Text('@${value.username} requested to follow you'),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Approve request',
                onPressed: () async {
                  try {
                    await ref
                        .read(socialRepositoryProvider)
                        .approveFollow(follow.id);
                    ref.invalidate(
                      socialFollowRequestsProvider(follow.followeeId),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    _showMessage(context, 'Could not approve request: $error');
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
              ),
              IconButton(
                tooltip: 'Decline request',
                onPressed: () async {
                  try {
                    await ref
                        .read(socialRepositoryProvider)
                        .removeFollow(follow.id);
                    ref.invalidate(
                      socialFollowRequestsProvider(follow.followeeId),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    _showMessage(context, 'Could not decline request: $error');
                  }
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
