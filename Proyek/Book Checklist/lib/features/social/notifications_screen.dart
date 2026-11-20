import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../providers/social_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _enablingPush = false;
  String? _pushMessage;

  Future<void> _enablePush(String uid) async {
    setState(() {
      _enablingPush = true;
      _pushMessage = null;
    });
    try {
      await ref.read(socialPushServiceProvider).enableForUser(uid);
      if (mounted) setState(() => _pushMessage = 'Push notifications enabled.');
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _pushMessage = 'Push notifications could not be enabled: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _enablingPush = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Sign in to view notifications.')),
      );
    }
    final notifications = ref.watch(socialNotificationsProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _enablingPush ? null : () => _enablePush(uid),
                  icon: _enablingPush
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _enablingPush
                        ? 'Enabling push...'
                        : 'Enable push notifications',
                  ),
                ),
                if (_pushMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _pushMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: notifications.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Notifications could not be loaded: $error'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('You are all caught up.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isRead
                                ? null
                                : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                            child: Icon(_iconFor(item.type)),
                          ),
                          title: Text('@${item.actorUsername}'),
                          subtitle: Text(item.message),
                          trailing: item.isRead
                              ? null
                              : Icon(
                                  Icons.circle,
                                  size: 9,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          onTap: () => _openNotification(
                            uid,
                            item.id,
                            item.actorUid,
                            item.targetId,
                            item.type,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotification(
    String uid,
    String notificationId,
    String actorUid,
    String targetId,
    String type,
  ) async {
    try {
      await ref
          .read(socialRepositoryProvider)
          .markNotificationRead(uid, notificationId);
      if (!mounted) return;
      if (targetId.isNotEmpty &&
          (type == 'new_comment' ||
              type == 'mutual_comment' ||
              type == 'mutual_post' ||
              type == 'mutual_rating')) {
        context.push('/community/post/$targetId');
      } else {
        context.push('/community/profile/$actorUid');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open notification: $error')),
        );
      }
    }
  }

  IconData _iconFor(String type) => switch (type) {
    'follow_request' => Icons.person_add_alt_1_outlined,
    'new_follower' || 'follow_accepted' => Icons.person_add_alt_rounded,
    'new_comment' => Icons.mode_comment_outlined,
    'mutual_rating' => Icons.star_outline_rounded,
    _ => Icons.dynamic_feed_outlined,
  };
}
