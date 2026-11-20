import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/social_repository.dart';
import '../data/social_push_service.dart';
import '../domain/social_models.dart';
import 'app_providers.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.watch(firebaseFirestoreProvider)),
);

final socialPushServiceProvider = Provider<SocialPushService>(
  (ref) => SocialPushService(
    FirebaseMessaging.instance,
    ref.watch(firebaseFirestoreProvider),
  ),
);

final currentSocialProfileProvider = FutureProvider<SocialProfile>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) throw StateError('Sign in to use the community.');
  return ref.watch(socialRepositoryProvider).ensureProfile(user);
});

final socialProfileProvider = FutureProvider.family<SocialProfile?, String>(
  (ref, uid) => ref.watch(socialRepositoryProvider).getProfile(uid),
);

final communityFeedProvider = StreamProvider.family<List<SocialPost>, String>(
  (ref, uid) => ref.watch(socialRepositoryProvider).watchFeed(uid),
);

final socialPostProvider = FutureProvider.family<SocialPost?, String>(
  (ref, postId) => ref.watch(socialRepositoryProvider).getPost(postId),
);

final socialFollowStatusProvider =
    FutureProvider.family<SocialFollowStatus?, (String, String)>(
      (ref, ids) => ref
          .watch(socialRepositoryProvider)
          .getFollowStatus(followerId: ids.$1, followeeId: ids.$2),
    );

final socialPostsByAuthorProvider =
    StreamProvider.family<List<SocialPost>, String>(
      (ref, uid) => ref.watch(socialRepositoryProvider).watchPostsByAuthor(uid),
    );

final socialCommentsProvider =
    StreamProvider.family<List<SocialComment>, String>(
      (ref, postId) =>
          ref.watch(socialRepositoryProvider).watchComments(postId),
    );

final socialFollowRequestsProvider =
    StreamProvider.family<List<SocialFollow>, String>(
      (ref, uid) =>
          ref.watch(socialRepositoryProvider).watchFollowRequests(uid),
    );

final socialNotificationsProvider =
    StreamProvider.family<List<SocialNotification>, String>(
      (ref, uid) => ref.watch(socialRepositoryProvider).watchNotifications(uid),
    );

final socialUnreadCountProvider = StreamProvider.family<int, String>(
  (ref, uid) => ref.watch(socialRepositoryProvider).watchUnreadCount(uid),
);
