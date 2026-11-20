import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/social_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/social_providers.dart';
import 'social_widgets.dart';

class SocialProfileScreen extends ConsumerWidget {
  const SocialProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isOwner = viewerId == uid;
    final profile = isOwner
        ? ref.watch(currentSocialProfileProvider)
        : ref.watch(socialProfileProvider(uid));
    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? 'Your community profile' : 'Reader profile'),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Profile could not be loaded: $error'),
          ),
        ),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('This profile no longer exists.'));
          }
          if (isOwner) return _profileContent(context, ref, value, true, true);
          if (viewerId == null) {
            return const Center(child: Text('Sign in to view this profile.'));
          }
          final status = ref.watch(
            socialFollowStatusProvider((viewerId, value.uid)),
          );
          return status.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Follow status could not be loaded: $error'),
              ),
            ),
            data: (followStatus) {
              final canSeePosts =
                  !value.isPrivate || followStatus == SocialFollowStatus.active;
              return _profileContent(
                context,
                ref,
                value,
                false,
                canSeePosts,
                viewerId: viewerId,
                followStatus: followStatus,
              );
            },
          );
        },
      ),
    );
  }

  Widget _profileContent(
    BuildContext context,
    WidgetRef ref,
    SocialProfile profile,
    bool isOwner,
    bool canSeePosts, {
    String? viewerId,
    SocialFollowStatus? followStatus,
  }) {
    final requests = isOwner
        ? ref.watch(socialFollowRequestsProvider(profile.uid))
        : null;
    final posts = canSeePosts
        ? ref.watch(socialPostsByAuthorProvider(profile.uid))
        : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(profile.username[0].toUpperCase()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '@${profile.username}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (profile.isPrivate)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('Private account'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    tooltip: 'Edit community profile',
                    onPressed: () => _editProfile(context, ref, profile),
                    icon: const Icon(Icons.edit_outlined),
                  )
                else if (viewerId != null)
                  _FollowButton(
                    profile: profile,
                    viewerId: viewerId,
                    status: followStatus,
                  ),
              ],
            ),
          ),
        ),
        if (isOwner)
          requests!.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => Card(
              child: ListTile(
                title: const Text('Follow requests could not be loaded.'),
                subtitle: Text('$error'),
              ),
            ),
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.person_add_alt_1_rounded),
                      title: Text('${items.length} follow request(s)'),
                      children: [
                        for (final request in items)
                          FollowRequestTile(follow: request),
                      ],
                    ),
                  ),
          ),
        const SizedBox(height: 10),
        if (!canSeePosts)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 36),
                  SizedBox(height: 10),
                  Text(
                    'Posts from this private account are visible to approved followers.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          posts!.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Card(
              child: ListTile(
                title: const Text('Posts could not be loaded.'),
                subtitle: Text('$error'),
              ),
            ),
            data: (items) => items.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No posts yet.', textAlign: TextAlign.center),
                    ),
                  )
                : Column(
                    children: [
                      for (final post in items) SocialPostCard(post: post),
                    ],
                  ),
          ),
      ],
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    SocialProfile profile,
  ) async {
    final updated = await showDialog<SocialProfile>(
      context: context,
      builder: (context) => _SocialProfileEditor(profile: profile),
    );
    if (updated != null) {
      ref.invalidate(currentSocialProfileProvider);
      ref.invalidate(socialProfileProvider(profile.uid));
    }
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({
    required this.profile,
    required this.viewerId,
    required this.status,
  });

  final SocialProfile profile;
  final String viewerId;
  final SocialFollowStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = switch (status) {
      SocialFollowStatus.active => 'Following',
      SocialFollowStatus.pending => 'Requested',
      null => profile.isPrivate ? 'Request to follow' : 'Follow',
    };
    return OutlinedButton(
      onPressed: () async {
        try {
          final repository = ref.read(socialRepositoryProvider);
          if (status == null) {
            await repository.follow(
              followerId: viewerId,
              followeeId: profile.uid,
            );
          } else {
            await repository.removeFollow('${viewerId}_${profile.uid}');
          }
          ref.invalidate(socialFollowStatusProvider((viewerId, profile.uid)));
          ref.invalidate(communityFeedProvider(viewerId));
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not update follow status: $error')),
            );
          }
        }
      },
      child: Text(status == null ? label : 'Unfollow'),
    );
  }
}

class _SocialProfileEditor extends ConsumerStatefulWidget {
  const _SocialProfileEditor({required this.profile});

  final SocialProfile profile;

  @override
  ConsumerState<_SocialProfileEditor> createState() =>
      _SocialProfileEditorState();
}

class _SocialProfileEditorState extends ConsumerState<_SocialProfileEditor> {
  late final _usernameController = TextEditingController(
    text: widget.profile.username,
  );
  bool _isPrivate = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.profile.isPrivate;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final validation = SocialProfile.validateUsername(_usernameController.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(socialRepositoryProvider)
          .updateProfile(
            uid: widget.profile.uid,
            username: _usernameController.text,
            displayName: widget.profile.displayName,
            isPrivate: _isPrivate,
          );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save profile: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Community profile'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _usernameController,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixText: '@',
            helperText: '3-20 characters: lowercase letters, numbers, _',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Private account'),
          subtitle: const Text('Approve followers before they see your posts'),
          value: _isPrivate,
          onChanged: _saving
              ? null
              : (value) => setState(() => _isPrivate = value),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving...' : 'Save'),
      ),
    ],
  );
}
