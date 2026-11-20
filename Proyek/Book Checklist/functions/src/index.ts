import { initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

initializeApp();

const db = getFirestore();

type NotificationInput = {
  id: string;
  recipientUid: string;
  actorUid: string;
  actorUsername: string;
  type: string;
  message: string;
  targetId?: string;
};

async function createNotification(input: NotificationInput): Promise<void> {
  if (input.recipientUid === input.actorUid) return;
  const notificationRef = db
    .collection("users")
    .doc(input.recipientUid)
    .collection("notifications")
    .doc(input.id);
  await notificationRef.set({
    type: input.type,
    actorUid: input.actorUid,
    actorUsername: input.actorUsername,
    message: input.message,
    targetId: input.targetId ?? "",
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function notifyMutualFollowers(
  authorUid: string,
  authorUsername: string,
  postId: string,
  eventId: string,
  type: string,
  message: string,
  excludedRecipients: string[] = [],
  requiredFolloweeUid?: string,
): Promise<void> {
  const followersQuery = db
    .collection("follows")
    .where("followeeId", "==", authorUid)
    .where("status", "==", "active");
  let cursor: QueryDocumentSnapshot | undefined;
  while (true) {
    const query = cursor
      ? followersQuery.startAfter(cursor).limit(100)
      : followersQuery.limit(100);
    const followers = await query.get();
    if (followers.empty) break;
    cursor = followers.docs[followers.docs.length - 1];
    const recipients = await Promise.all(
      followers.docs.map(async (follow) => {
        const followerUid = follow.get("followerId") as string;
        if (
          followerUid === authorUid ||
          excludedRecipients.includes(followerUid)
        ) {
          return null;
        }
        if (requiredFolloweeUid) {
          const canReadPrivatePost = await db
            .doc(`follows/${followerUid}_${requiredFolloweeUid}`)
            .get();
          if (
            !canReadPrivatePost.exists ||
            canReadPrivatePost.get("status") !== "active"
          ) {
            return null;
          }
        }
        const reciprocal = await db.doc(`follows/${authorUid}_${followerUid}`).get();
        return reciprocal.exists && reciprocal.get("status") === "active"
          ? followerUid
          : null;
      }),
    );
    const recipientUids = recipients.filter(
      (uid): uid is string => uid !== null,
    );
    if (recipientUids.length === 0) continue;
    const batch = db.batch();
    for (const recipientUid of recipientUids) {
      const notificationRef = db
        .collection("users")
        .doc(recipientUid)
        .collection("notifications")
        .doc(`${eventId}_${type}`);
      batch.set(notificationRef, {
        type,
        actorUid: authorUid,
        actorUsername: authorUsername,
        message,
        targetId: postId,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

export const notifyOnFollowCreated = onDocumentCreated(
  "follows/{followId}",
  async (event) => {
    const follow = event.data?.data();
    if (!follow) return;
    const followerUid = follow.followerId as string;
    const followeeUid = follow.followeeId as string;
    const followerProfile = await db.doc(`profiles/${followerUid}`).get();
    const actorUsername = (followerProfile.get("username") as string | undefined) ?? "reader";
    const pending = follow.status === "pending";
    await createNotification({
      id: `${event.params.followId}_${pending ? "request" : "follow"}`,
      recipientUid: followeeUid,
      actorUid: followerUid,
      actorUsername,
      type: pending ? "follow_request" : "new_follower",
      message: pending ? "requested to follow you" : "started following you",
    });
  },
);

export const notifyOnFollowApproved = onDocumentUpdated(
  "follows/{followId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status !== "pending" || after.status !== "active") {
      return;
    }
    const followeeProfile = await db.doc(`profiles/${after.followeeId as string}`).get();
    await createNotification({
      id: `${event.params.followId}_accepted`,
      recipientUid: after.followerId as string,
      actorUid: after.followeeId as string,
      actorUsername:
        (followeeProfile.get("username") as string | undefined) ?? "reader",
      type: "follow_accepted",
      message: "accepted your follow request",
    });
  },
);

export const notifyMutualsOnPost = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const post = event.data?.data();
    if (!post) return;
    const isRating = post.kind === "rating";
    const mediaTitle = (post.mediaTitle as string | undefined) ?? "";
    const ratingText =
      typeof post.rating === "number" ? ` (${post.rating}/5)` : "";
    const message = isRating
      ? `rated ${mediaTitle || "a title"}${ratingText}`
      : "shared a new post";
    await notifyMutualFollowers(
      post.authorId as string,
      post.authorUsername as string,
      event.params.postId,
      event.params.postId,
      isRating ? "mutual_rating" : "mutual_post",
      message,
    );
  },
);

export const notifyOnComment = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;
    const postSnapshot = await db.doc(`posts/${event.params.postId}`).get();
    if (!postSnapshot.exists) return;
    const post = postSnapshot.data()!;
    const commenterUid = comment.authorId as string;
    if (post.authorId === commenterUid) return;
    const commenterProfile = await db.doc(`profiles/${commenterUid}`).get();
    const commenterUsername =
      (commenterProfile.get("username") as string | undefined) ?? "reader";
    await createNotification({
      id: `${event.params.postId}_${event.params.commentId}`,
      recipientUid: post.authorId as string,
      actorUid: commenterUid,
      actorUsername: comment.authorUsername as string,
      type: "new_comment",
      message: `commented: ${(comment.text as string).slice(0, 100)}`,
      targetId: event.params.postId,
    });
    await notifyMutualFollowers(
      commenterUid,
      commenterUsername,
      event.params.postId,
      event.params.commentId,
      "mutual_comment",
      "commented on a community post",
      [post.authorId as string],
      post.visibility === "followers" ? (post.authorId as string) : undefined,
    );
  },
);

export const deliverPushNotification = onDocumentCreated(
  "users/{uid}/notifications/{notificationId}",
  async (event) => {
    const notification = event.data?.data();
    if (!notification) return;
    const tokenSnapshot = await db
      .collection("users")
      .doc(event.params.uid)
      .collection("fcm_tokens")
      .get();
    if (tokenSnapshot.empty) return;

    for (let offset = 0; offset < tokenSnapshot.docs.length; offset += 500) {
      const tokenDocuments = tokenSnapshot.docs.slice(offset, offset + 500);
      const tokens = tokenDocuments.map(
        (document) => document.get("token") as string,
      );
      const response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: notification.actorUsername as string,
          body: notification.message as string,
        },
        data: {
          type: notification.type as string,
          targetId: (notification.targetId as string | undefined) ?? "",
          actorUid: notification.actorUid as string,
        },
      });
      const invalidTokens = response.responses
        .map((result, index) => ({ result, ref: tokenDocuments[index].ref }))
        .filter(
          ({ result }) =>
            !result.success &&
            (result.error?.code === "messaging/invalid-registration-token" ||
              result.error?.code === "messaging/registration-token-not-registered"),
        );
      const failures = response.responses.filter((result) => !result.success);
      if (failures.length > invalidTokens.length) {
        logger.error("One or more push notifications failed.", {
          failedCount: failures.length - invalidTokens.length,
        });
      }
      if (invalidTokens.length > 0) {
        const batch = db.batch();
        for (const { ref } of invalidTokens) batch.delete(ref);
        await batch.commit();
      }
    }
  },
);
