import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/social_models.dart';
import '../../providers/social_providers.dart';
import 'social_widgets.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  List<SocialProfile> _searchResults = const [];
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      final text = message.notification?.body;
      if (text != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final profiles = await ref
            .read(socialRepositoryProvider)
            .searchProfiles(query);
        if (mounted && _searchController.text.trim() == query) {
          setState(() {
            _searchResults = profiles;
            _searching = false;
          });
        }
      } catch (error) {
        if (mounted && _searchController.text.trim() == query) {
          setState(() {
            _searchError = 'Could not search profiles: $error';
            _searching = false;
          });
        }
      }
    });
  }

  Future<void> _compose(SocialProfile profile) async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ComposePostSheet(profile: profile),
    );
    if (posted == true && mounted) {
      ref.invalidate(communityFeedProvider(profile.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentSocialProfileProvider);
    return currentProfile.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Community')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Community')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Your community profile could not be loaded: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(currentSocialProfileProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) => Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          actions: [
            _NotificationButton(uid: profile.uid),
            IconButton(
              tooltip: 'Your community profile',
              onPressed: () =>
                  context.push('/community/profile/${profile.uid}'),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _compose(profile),
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Post'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Find readers by username',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: _searchController.text.trim().length >= 2
                    ? _buildSearchResults()
                    : _buildFeed(profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(child: Text(_searchError!));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No readers found.'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final profile = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(child: Text(profile.username[0].toUpperCase())),
          title: Text(profile.displayName),
          subtitle: Text(
            '@${profile.username}${profile.isPrivate ? ' · Private' : ''}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/community/profile/${profile.uid}'),
        );
      },
    );
  }

  Widget _buildFeed(SocialProfile profile) {
    final feed = ref.watch(communityFeedProvider(profile.uid));
    final requests = ref.watch(socialFollowRequestsProvider(profile.uid));
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The community feed could not be loaded.'),
              const SizedBox(height: 6),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(communityFeedProvider(profile.uid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (posts) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(profile.username[0].toUpperCase()),
              ),
              title: const Text('Share a thought or a rating'),
              subtitle: Text(
                profile.isPrivate
                    ? 'Only your followers will see it'
                    : 'Visible to everyone in MyShelf',
              ),
              trailing: const Icon(Icons.add_circle_outline_rounded),
              onTap: () => _compose(profile),
            ),
          ),
          requests.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline_rounded),
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
          if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Text(
                'Your feed is quiet for now. Find readers or share your first post.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final post in posts) SocialPostCard(post: post),
        ],
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(socialUnreadCountProvider(uid)).asData?.value ?? 0;
    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
