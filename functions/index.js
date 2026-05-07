const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

/**
 * Kullanıcı için uygulama içi bildirim oluşturur.
 */
async function createInAppNotification({
  userId,
  title,
  message,
  type,
  targetRoute,
}) {
  if (!userId) return;

  await db.collection("notifications").add({
    userId,
    title,
    message,
    type,
    targetRoute,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

/**
 * Kullanıcıya push bildirimi gönderir.
 */
async function sendPushToUser({
  userId,
  title,
  body,
  route,
}) {
  if (!userId) return;

  const userDoc = await db.collection("users").doc(userId).get();

  if (!userDoc.exists) return;

  const fcmToken = userDoc.data().fcmToken;

  if (!fcmToken) return;

  await getMessaging().send({
    token: fcmToken,
    notification: {
      title,
      body,
    },
    data: {
      route: route || "/notifications",
    },
  });
}

exports.onCommentCreated = onDocumentCreated(
    "posts/{postId}/comments/{commentId}",
    async (event) => {
      const comment = event.data.data();
      const postId = event.params.postId;

      const postDoc = await db.collection("posts").doc(postId).get();
      if (!postDoc.exists) return;

      const post = postDoc.data();
      const postOwnerId = post.userId;

      if (!postOwnerId || postOwnerId === comment.userId) return;

      const title = "Yeni yorum";
      const username = comment.username || "Bir taraftar";
      const message = `${username} postuna yorum yaptı.`;
      const targetRoute = `/post/${postId}`;

      await createInAppNotification({
        userId: postOwnerId,
        title,
        message,
        type: "comment",
        targetRoute,
      });

      await sendPushToUser({
        userId: postOwnerId,
        title,
        body: message,
        route: targetRoute,
      });
    },
);

exports.onReportUpdated = onDocumentUpdated(
    "reports/{reportId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (before.status === after.status) return;

      const title = "Rapor durumu güncellendi";
      const message = `Raporun durumu: ${after.status}`;
      const targetRoute = "/reports";

      await createInAppNotification({
        userId: after.reporterId,
        title,
        message,
        type: "report",
        targetRoute,
      });

      await sendPushToUser({
        userId: after.reporterId,
        title,
        body: message,
        route: targetRoute,
      });
    },
);

exports.onMatchCreated = onDocumentCreated(
    "matches/{matchId}",
    async (event) => {
      const match = event.data.data();
      const matchId = event.params.matchId;

      const title = "Yeni maç eklendi";
      const body = `${match.homeTeam} vs ${match.awayTeam} maçı eklendi.`;
      const route = `/prediction/${matchId}`;

      // Global topic 'all_users' üzerinden tek bir push bildirimi gönderiyoruz
      // Böylece yüz binlerce kullanıcı için Firestore doküman okuma/yazma 
      // (ve devasa fatura riski) ortadan kalkmış olur.
      try {
        await getMessaging().send({
          topic: "all_users",
          notification: {
            title,
            body,
          },
          data: {
            route,
          },
        });
        console.log(`Successfully sent match notification for ${matchId}`);
      } catch (error) {
        console.error("Error sending match notification:", error);
      }
    },
);

exports.onPredictionUpdated = onDocumentUpdated(
    "predictions/{predictionId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (before.pointsEarned === after.pointsEarned) return;
      if (!after.userId) return;

      await db.collection("users").doc(after.userId).update({
        points: FieldValue.increment(after.pointsEarned || 0),
      });

      const title = "Tahmin sonucu";
      const message = `${after.pointsEarned || 0} puan kazandın.`;
      const targetRoute = "/predictions/me";

      await createInAppNotification({
        userId: after.userId,
        title,
        message,
        type: "prediction",
        targetRoute,
      });

      await sendPushToUser({
        userId: after.userId,
        title,
        body: message,
        route: targetRoute,
      });
    },
);
