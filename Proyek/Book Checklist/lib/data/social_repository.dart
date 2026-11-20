import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/social_models.dart';

class SocialRepository {
  SocialRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');
  CollectionReference<Map<String, dynamic>> get _follows =>
      _firestore.collection('follows');
  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Future<SocialProfile> ensureProfile(User user) async {
    final profileRef = _profiles.doc(user.uid);
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'Reader';
    final baseUsername = _usernameBase(displayName);

    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(profileRef);
      if (existing.exists) return SocialProfile.fromMap(existing.data()!);

      final candidates = [
        baseUsername,
        _fitUsername('${baseUsername}_${user.uid.substring(0, 6)}'),
        'r_${user.uid.substring(0, 18)}',
      ];
      String? username;
      DocumentReference<Map<String, dynamic>>? usernameRef;
      for (final candidate in candidates) {
        final candidateRef = _usernames.doc(candidate);
        final candidateSnapshot = await transaction.get(candidateRef);
        if (!candidateSnapshot.exists) {
          username = candidate;
          usernameRef = candidateRef;
          break;
        }
      }
      if (username == null || usernameRef == null) {
        throw StateError('A unique username could not be generated.');
      }

      transaction.set(usernameRef, {'uid': user.uid, 'username': username});
      transaction.set(profileRef, {
        'uid': user.uid,
        'username': username,
        'usernameLower': username,
        'displayName': displayName,
        'isPrivate': false,
        'privacyUpdating': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return SocialProfile(
        uid: user.uid,
        username: username,
        displayName: displayName,
        isPrivate: false,
      );
    });
  }

  Future<SocialProfile> updateProfile({
    required String uid,
    required String username,
    required String displayName,
    required bool isPrivate,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final validationError = SocialProfile.validateUsername(normalizedUsername);
    if (validationError != null) throw ArgumentError(validationError);
    final profileRef = _profiles.doc(uid);
    var before = await profileRef.get();
    if (!before.exists) {
      throw StateError('Your community profile could not be found.');
    }
    var beforeData = before.data()!;
    var beforeProfile = SocialProfile.fromMap(beforeData);
    if (beforeData['privacyUpdating'] == true) {
      if (!_privacyUpdateIsStale(beforeData)) {
        throw StateError('Your privacy setting is still being updated.');
      }
      await _updatePostVisibility(uid, private: beforeProfile.isPrivate);
      await _setPrivacyUpdating(uid, false);
      before = await profileRef.get();
      if (!before.exists) {
        throw StateError('Your community profile could not be found.');
      }
      beforeData = before.data()!;
      beforeProfile = SocialProfile.fromMap(beforeData);
    }

    if (beforeProfile.isPrivate == isPrivate) {
      return _commitProfileUpdate(
        uid: uid,
        username: normalizedUsername,
        displayName: displayName,
        isPrivate: isPrivate,
        expectedPrivate: beforeProfile.isPrivate,
        expectedPrivacyUpdating: false,
        privacyUpdating: false,
      );
    }

    await _setPrivacyUpdating(uid, true);
    try {
      if (isPrivate) {
        await _updatePostVisibility(uid, private: true);
        return await _commitProfileUpdate(
          uid: uid,
          username: normalizedUsername,
          displayName: displayName,
          isPrivate: true,
          expectedPrivate: false,
          expectedPrivacyUpdating: true,
          privacyUpdating: false,
        );
      }

      final updated = await _commitProfileUpdate(
        uid: uid,
        username: normalizedUsername,
        displayName: displayName,
        isPrivate: false,
        expectedPrivate: true,
        expectedPrivacyUpdating: true,
        privacyUpdating: true,
      );
      await _updatePostVisibility(uid, private: false);
      await _setPrivacyUpdating(uid, false);
      return updated;
    } catch (error) {
      try {
        await _setPrivacyUpdating(uid, false);
      } catch (cleanupError) {
        throw StateError(
          'Privacy update failed: $error. The transition could not be '
          'cleared: $cleanupError',
        );
      }
      rethrow;
    }
  }

  Future<SocialProfile> _commitProfileUpdate({
    required String uid,
    required String username,
    required String displayName,
    required bool isPrivate,
    required bool expectedPrivate,
    required bool expectedPrivacyUpdating,
    required bool privacyUpdating,
  }) async {
    final profileRef = _profiles.doc(uid);
    final nextUsernameRef = _usernames.doc(username);
    return _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(profileRef);
      if (!profileSnapshot.exists) {
        throw StateError('Your community profile could not be found.');
      }
      final data = profileSnapshot.data()!;
      final current = SocialProfile.fromMap(data);
      if (current.isPrivate != expectedPrivate ||
          (data['privacyUpdating'] == true) != expectedPrivacyUpdating) {
        throw StateError('Your profile changed. Please try again.');
      }
      if (current.usernameLower != username) {
        final usernameSnapshot = await transaction.get(nextUsernameRef);
        if (usernameSnapshot.exists) {
          throw StateError('That username is already taken.');
        }
        transaction.delete(_usernames.doc(current.usernameLower));
        transaction.set(nextUsernameRef, {'uid': uid, 'username': username});
      }

      final next = SocialProfile(
        uid: uid,
        username: username,
        displayName: displayName.trim().isEmpty
            ? current.displayName
            : displayName.trim(),
        isPrivate: isPrivate,
      );
      transaction.update(profileRef, {
        'username': next.username,
        'usernameLower': next.usernameLower,
        'displayName': next.displayName,
        'isPrivate': next.isPrivate,
        'privacyUpdating': privacyUpdating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
  }

  Future<void> _setPrivacyUpdating(String uid, bool updating) =>
      _firestore.runTransaction((transaction) async {
        final profileRef = _profiles.doc(uid);
        final snapshot = await transaction.get(profileRef);
        if (!snapshot.exists) {
          throw StateError('Your community profile could not be found.');
        }
        final current = snapshot.data()!['privacyUpdating'] == true;
        if (current == updating) return;
        if (updating && current) {
          throw StateError('A privacy update is already in progress.');
        }
        transaction.update(profileRef, {
          'privacyUpdating': updating,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  bool _privacyUpdateIsStale(Map<String, dynamic> profile) {
    final updatedAt = profile['updatedAt'];
    return updatedAt is Timestamp &&
        DateTime.now().difference(updatedAt.toDate()) >
            const Duration(minutes: 10);
  }

  Future<SocialProfile?> getProfile(String uid) async {
    final snapshot = await _profiles.doc(uid).get();
    final data = snapshot.data();
    return data == null ? null : SocialProfile.fromMap(data);
  }

  Future<List<SocialProfile>> searchProfiles(String value) async {
    final prefix = value.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (prefix.isEmpty) return const [];
    final snapshot = await _profiles
        .orderBy('usernameLower')
        .startAt([prefix])
        .endAt(['$prefix\uf8ff'])
        .limit(20)
        .get();
    return snapshot.docs
        .map((document) => SocialProfile.fromMap(document.data()))
        .toList(growable: false);
  }

  Stream<List<SocialPost>> watchFeed(String uid) {
    late final StreamController<List<SocialPost>> controller;
    final sourcePosts = <String, Map<String, SocialPost>>{};
    var activeSources = <String>{'self'};
    final postSubscriptions =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    followsSubscription;

    void emit() {
      if (controller.isClosed) return;
      final unique = <String, SocialPost>{};
      for (final posts in sourcePosts.values) {
        unique.addAll(posts);
      }
      final result = unique.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(result.take(60).toList(growable: false));
    }

    void subscribeToPosts(String source, Query<Map<String, dynamic>> query) {
      postSubscriptions[source] = query.snapshots().listen(
        (snapshot) {
          if (source != 'public' && !activeSources.contains(source)) return;
          sourcePosts[source] = {
            for (final document in snapshot.docs)
              document.id: SocialPost.fromDocument(document),
          };
          emit();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed &&
              (source == 'public' || activeSources.contains(source))) {
            controller.addError(error, stackTrace);
          }
        },
      );
    }

    controller = StreamController<List<SocialPost>>(
      onListen: () {
        subscribeToPosts(
          'public',
          _posts
              .where('visibility', isEqualTo: 'public')
              .orderBy('createdAt', descending: true)
              .limit(30),
        );
        subscribeToPosts(
          'self',
          _posts
              .where('authorId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(30),
        );
        followsSubscription = _follows
            .where('followerId', isEqualTo: uid)
            .where('status', isEqualTo: 'active')
            .snapshots()
            .listen(
              (snapshot) {
                final authors = snapshot.docs
                    .map((document) => document.data()['followeeId'] as String)
                    .toSet();
                final expectedSources = authors
                    .map((authorId) => 'author-$authorId')
                    .toSet();
                expectedSources.add('self');
                activeSources = expectedSources;
                for (final source in postSubscriptions.keys.toList()) {
                  if (source != 'public' && !expectedSources.contains(source)) {
                    postSubscriptions.remove(source)?.cancel();
                    sourcePosts.remove(source);
                  }
                }
                for (final authorId in authors) {
                  final source = 'author-$authorId';
                  if (postSubscriptions.containsKey(source)) continue;
                  subscribeToPosts(
                    source,
                    _posts
                        .where('authorId', isEqualTo: authorId)
                        .orderBy('createdAt', descending: true)
                        .limit(30),
                  );
                }
                emit();
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
              },
            );
      },
      onCancel: () async {
        await followsSubscription?.cancel();
        for (final subscription in postSubscriptions.values) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<List<SocialPost>> watchPostsByAuthor(String authorId) => _posts
      .where('authorId', isEqualTo: authorId)
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(SocialPost.fromDocument).toList(growable: false),
      );

  Future<SocialPost?> getPost(String postId) async {
    final snapshot = await _posts.doc(postId).get();
    return snapshot.exists ? SocialPost.fromDocument(snapshot) : null;
  }

  Future<void> _updatePostVisibility(
    String uid, {
    required bool private,
  }) async {
    final postsQuery = _posts
        .where('authorId', isEqualTo: uid)
        .orderBy(FieldPath.documentId)
        .limit(400);
    final visibility = private ? 'followers' : 'public';
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      final query = cursor == null
          ? postsQuery
          : postsQuery.startAfterDocument(cursor);
      final posts = await query.get();
      if (posts.docs.isEmpty) break;
      final batch = _firestore.batch();
      var hasUpdates = false;
      for (final post in posts.docs) {
        if (post.data()['visibility'] != visibility) {
          batch.update(post.reference, {'visibility': visibility});
          hasUpdates = true;
        }
      }
      if (hasUpdates) await batch.commit();
      cursor = posts.docs.last;
      if (posts.docs.length < 400) break;
    }
  }

  Stream<List<SocialComment>> watchComments(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(SocialComment.fromDocument)
            .toList(growable: false),
      );

  Future<void> createPost({
    required SocialProfile author,
    required SocialPostKind kind,
    required String text,
    required String mediaTitle,
    required String mediaType,
    double? rating,
  }) async {
    final trimmedText = text.trim();
    final trimmedTitle = mediaTitle.trim();
    if (trimmedText.isEmpty && trimmedTitle.isEmpty) {
      throw ArgumentError('Add a comment or a media title before posting.');
    }
    if (kind == SocialPostKind.rating && rating == null) {
      throw ArgumentError('Choose a rating before sharing it.');
    }
    await _posts.add({
      'authorId': author.uid,
      'authorUsername': author.username,
      'authorDisplayName': author.displayName,
      'kind': kind.name,
      'text': trimmedText,
      'mediaTitle': trimmedTitle,
      'mediaType': mediaType,
      'rating': rating,
      'visibility': author.isPrivate ? 'followers' : 'public',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) throw ArgumentError('Comment cannot be empty.');
    await _posts.doc(postId).collection('comments').add({
      'authorId': authorId,
      'authorUsername': authorUsername,
      'text': trimmedText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<SocialFollowStatus?> getFollowStatus({
    required String followerId,
    required String followeeId,
  }) async {
    final snapshot = await _follows.doc('${followerId}_$followeeId').get();
    final status = snapshot.data()?['status'] as String?;
    return status == null ? null : SocialFollowStatus.values.byName(status);
  }

  Future<void> follow({
    required String followerId,
    required String followeeId,
  }) async {
    if (followerId == followeeId) {
      throw ArgumentError('You cannot follow your own account.');
    }
    final followRef = _follows.doc('${followerId}_$followeeId');
    final profileRef = _profiles.doc(followeeId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(followRef);
      if (existing.exists) return;
      final profile = await transaction.get(profileRef);
      if (!profile.exists) throw StateError('This profile no longer exists.');
      final isPrivate = profile.data()!['isPrivate'] as bool? ?? false;
      final now = FieldValue.serverTimestamp();
      transaction.set(followRef, {
        'followerId': followerId,
        'followeeId': followeeId,
        'status': isPrivate ? 'pending' : 'active',
        'createdAt': now,
        'updatedAt': now,
      });
    });
  }

  Future<void> approveFollow(String followId) async {
    await _follows.doc(followId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFollow(String followId) => _follows.doc(followId).delete();

  Stream<List<SocialFollow>> watchFollowRequests(String uid) => _follows
      .where('followeeId', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(SocialFollow.fromDocument)
            .toList(growable: false),
      );

  Stream<List<SocialNotification>> watchNotifications(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(SocialNotification.fromDocument)
            .toList(growable: false),
      );

  Stream<int> watchUnreadCount(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.size);

  Future<void> markNotificationRead(String uid, String notificationId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});

  String _usernameBase(String displayName) {
    var value = displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (value.isEmpty || !RegExp(r'^[a-z]').hasMatch(value)) {
      value = 'reader_$value';
    }
    if (value.length < 3) value = 'reader_$value';
    return _fitUsername(value);
  }

  String _fitUsername(String value) => value.length <= 20
      ? value
      : value.substring(0, 20).replaceAll(RegExp(r'_+$'), '');
}
