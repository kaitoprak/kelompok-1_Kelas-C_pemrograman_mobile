import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialFollowStatus { pending, active }

enum SocialPostKind { post, rating }

class SocialFollow {
  const SocialFollow({
    required this.id,
    required this.followerId,
    required this.followeeId,
    required this.status,
  });

  final String id;
  final String followerId;
  final String followeeId;
  final SocialFollowStatus status;

  factory SocialFollow.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data()!;
    return SocialFollow(
      id: document.id,
      followerId: map['followerId'] as String,
      followeeId: map['followeeId'] as String,
      status: SocialFollowStatus.values.byName(map['status'] as String),
    );
  }
}

class SocialProfile {
  const SocialProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.isPrivate,
  });

  final String uid;
  final String username;
  final String displayName;
  final bool isPrivate;

  String get usernameLower => username.toLowerCase();

  factory SocialProfile.fromMap(Map<String, dynamic> map) => SocialProfile(
    uid: map['uid'] as String,
    username: map['username'] as String,
    displayName: map['displayName'] as String,
    isPrivate: map['isPrivate'] as bool? ?? false,
  );

  static String? validateUsername(String value) {
    final username = value.trim().toLowerCase();
    if (username.length < 3 || username.length > 20) {
      return 'Username must be 3-20 characters.';
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(username)) {
      return 'Use lowercase letters, numbers, and underscores.';
    }
    return null;
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.kind,
    required this.text,
    required this.mediaTitle,
    required this.mediaType,
    required this.visibility,
    required this.createdAt,
    this.rating,
  });

  final String id;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final SocialPostKind kind;
  final String text;
  final String mediaTitle;
  final String mediaType;
  final String visibility;
  final DateTime createdAt;
  final double? rating;

  factory SocialPost.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data()!;
    return SocialPost(
      id: document.id,
      authorId: map['authorId'] as String,
      authorUsername: map['authorUsername'] as String,
      authorDisplayName: map['authorDisplayName'] as String,
      kind: SocialPostKind.values.byName(map['kind'] as String),
      text: map['text'] as String? ?? '',
      mediaTitle: map['mediaTitle'] as String? ?? '',
      mediaType: map['mediaType'] as String? ?? '',
      visibility: map['visibility'] as String,
      createdAt: _dateTime(map['createdAt']),
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }
}

class SocialComment {
  const SocialComment({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorUsername;
  final String text;
  final DateTime createdAt;

  factory SocialComment.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data()!;
    return SocialComment(
      id: document.id,
      authorId: map['authorId'] as String,
      authorUsername: map['authorUsername'] as String,
      text: map['text'] as String,
      createdAt: _dateTime(map['createdAt']),
    );
  }
}

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorUsername,
    required this.message,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String actorUid;
  final String actorUsername;
  final String message;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  factory SocialNotification.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data()!;
    return SocialNotification(
      id: document.id,
      type: map['type'] as String,
      actorUid: map['actorUid'] as String,
      actorUsername: map['actorUsername'] as String,
      message: map['message'] as String,
      targetId: map['targetId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _dateTime(map['createdAt']),
    );
  }
}

DateTime _dateTime(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  DateTime dateTime => dateTime,
  _ => DateTime.now(),
};
