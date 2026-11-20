import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/social_models.dart';
import '../../providers/social_providers.dart';
import 'social_widgets.dart';

class SocialPostScreen extends ConsumerStatefulWidget {
  const SocialPostScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<SocialPostScreen> createState() => _SocialPostScreenState();
}

class _SocialPostScreenState extends ConsumerState<SocialPostScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment(SocialProfile profile) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(socialRepositoryProvider)
          .addComment(
            postId: widget.postId,
            authorId: profile.uid,
            authorUsername: profile.username,
            text: _commentController.text,
          );
      _commentController.clear();
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not add comment: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(socialPostProvider(widget.postId));
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: post.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('This conversation could not be loaded: $error'),
          ),
        ),
        data: (value) {
          if (value == null) {
            return const Center(
              child: Text('This post is no longer available.'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    SocialPostCard(post: value),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _CommentList(postId: widget.postId),
                  ],
                ),
              ),
              _CommentComposer(
                controller: _commentController,
                sending: _sending,
                error: _error,
                onSend: _sendComment,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentList extends ConsumerWidget {
  const _CommentList({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(socialCommentsProvider(postId));
    return comments.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Text('Comments could not be loaded: $error'),
      data: (items) => items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Be the first to comment.'),
            )
          : Column(
              children: [
                for (final comment in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(comment.authorUsername[0].toUpperCase()),
                    ),
                    title: InkWell(
                      onTap: () => context.push(
                        '/community/profile/${comment.authorId}',
                      ),
                      child: Text('@${comment.authorUsername}'),
                    ),
                    subtitle: Text(comment.text),
                  ),
              ],
            ),
    );
  }
}

class _CommentComposer extends ConsumerWidget {
  const _CommentComposer({
    required this.controller,
    required this.sending,
    required this.error,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final String? error;
  final Future<void> Function(SocialProfile profile) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentSocialProfileProvider);
    return profile.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Commenting is unavailable: $error'),
      ),
      data: (value) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send comment',
                    onPressed: sending ? null : () => onSend(value),
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
