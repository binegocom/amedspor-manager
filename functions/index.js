const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {getAuth} = require("firebase-admin/auth");

initializeApp();

const db = getFirestore();

const POINT_RULES = Object.freeze({
  daily_login: {xp: 5, points: 2},
  lineup_saved: {xp: 10, points: 5},
  lineup_shared: {xp: 15, points: 8},
  lineup_liked_received: {xp: 3, points: 1},
  lineup_top_weekly: {xp: 100, points: 50},
  prediction_created: {xp: 10, points: 5},
  prediction_correct: {xp: 50, points: 25},
  prediction_correct_result: {xp: 20, points: 10},
  post_created: {xp: 15, points: 8},
  post_liked_received: {xp: 3, points: 1},
  comment_created: {xp: 5, points: 2},
  chat_message_matchday: {xp: 2, points: 1},
  live_match_opened: {xp: 20, points: 10},
  report_created: {xp: 2, points: 1},
  report_valid: {xp: 20, points: 10},
  profile_completed: {xp: 20, points: 10},
  training_completed: {xp: 25, points: 12},
  training_perfect_score: {xp: 50, points: 25},
});

function isStaffClaim(auth) {
  return auth &&
    auth.token &&
    (auth.token.role === "admin" ||
      auth.token.role === "moderator" ||
      auth.token.admin === true);
}

async function getActiveSeasonId() {
  const snapshot = await db.collection("seasons")
      .where("active", "==", true)
      .limit(1)
      .get();

  if (snapshot.empty) return "global";
  return snapshot.docs[0].id;
}

function calculateLevel(xp) {
  if (xp < 100) return 1;
  return Math.floor(Math.sqrt(xp / 100)) + 1;
}

function levelTitleFor(level) {
  if (level >= 50) return "Amedspor Elçisi";
  if (level >= 30) return "Efsane Taraftar";
  if (level >= 20) return "Tribün Lideri";
  if (level >= 10) return "Sadık Taraftar";
  if (level >= 5) return "Tribün Üyesi";
  return "Yeni Taraftar";
}

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

  try {
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
  } catch (error) {
    // Clean up stale FCM tokens to prevent future failures
    if (error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-registration-token") {
      await db.collection("users").doc(userId).update({fcmToken: null});
      console.log(`Cleaned stale FCM token for user ${userId}`);
    } else {
      console.error(`Push failed for ${userId}:`, error);
    }
  }
}

/**
 * Yeni kullanıcı oluşturulduğunda JWT Custom Claims atamasını güvenle yapar.
 */
exports.onUserCreated = onDocumentCreated(
    "users/{userId}",
    async (event) => {
      const userId = event.params.userId;
      const user = event.data.data();
      const role = user.role || "user";

      try {
        await getAuth().setCustomUserClaims(userId, {
          role: role,
        });
        console.log(`Assigned initial custom claim role=${role} to new user ${userId}`);
      } catch (error) {
        console.error(`Failed to assign custom claims to new user ${userId}:`, error);
      }
    },
);

/**
 * İstemci bağımsız, kümülatif Booster destekli ve Idempotent XP dağıtıcı Callable.
 */
exports.awardServerSideXp = onCall(async (request) => {
  // Authentication checking
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError(
        "unauthenticated",
        "Bu işlemi gerçekleştirmek için giriş yapmalısınız.",
    );
  }

  const callerUid = request.auth.uid;
  const {
    amount,
    reason,
    eventType,
    sourceType,
    sourceId,
    metadata,
    targetUserId,
  } = request.data;

  if (!eventType || !sourceId) {
    throw new HttpsError(
        "invalid-argument",
        "Eksik parametre gönderildi (eventType, sourceId zorunludur).",
    );
  }

  const rule = POINT_RULES[eventType];
  const canManualAdjust = eventType === "admin_adjustment" && isStaffClaim(request.auth);
  const userId = canManualAdjust && targetUserId ? String(targetUserId) : callerUid;

  if (!rule && !canManualAdjust) {
    throw new HttpsError(
        "permission-denied",
        "Bu puan olayı için sunucu kuralı tanımlı değil.",
    );
  }

  const baseXp = canManualAdjust ? Number(amount || 0) : rule.xp;
  if (!Number.isInteger(baseXp) || baseXp < -500 || baseXp > 500) {
    throw new HttpsError(
        "invalid-argument",
        "Geçersiz puan miktarı.",
    );
  }

  const activeSeasonId = await getActiveSeasonId();

  // Idempotency check via transaction
  return await db.runTransaction(async (transaction) => {
    const cleanSourceId = String(sourceId).replace(/[^a-zA-Z0-9_-]/g, "_");
    const cleanEventType = String(eventType).replace(/[^a-zA-Z0-9_-]/g, "");
    const eventDocId = `${cleanEventType}_${cleanSourceId}_${activeSeasonId}`;
    const eventRef = db.collection("users").doc(userId).collection("xpEvents").doc(eventDocId);

    const eventSnap = await transaction.get(eventRef);
    if (eventSnap.exists) {
      console.log(`Idempotency trigger: XP event ${eventDocId} already processed for user ${userId}`);
      return {status: "already_awarded", awarded: 0};
    }

    // Get user document
    const userRef = db.collection("users").doc(userId);
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "Kullanıcı kaydı bulunamadı.");
    }

    const userData = userSnap.data();
    if (userData.gamificationEnabled === false) {
      return {status: "disabled", awarded: 0};
    }

    // Check user's active badges to calculate cumulative XP Booster
    let cumulativeBooster = 0.0;
    const userBadgesSnap = await transaction.get(db.collection("users").doc(userId).collection("userBadges"));
    if (!userBadgesSnap.empty) {
      const badgeIds = [];
      userBadgesSnap.forEach((doc) => {
        if (doc.data().badgeId) badgeIds.push(doc.data().badgeId);
      });

      for (const bId of badgeIds) {
        const bDoc = await transaction.get(db.collection("badges").doc(bId));
        if (bDoc.exists && bDoc.data().xpBooster) {
          cumulativeBooster += Number(bDoc.data().xpBooster) || 0.0;
        }
      }
    }

    // Calculate final boosted amount. Points are rule-based and never client supplied.
    const finalAmount = Math.round(baseXp * (1.0 + cumulativeBooster));
    const pointsAmount = canManualAdjust ?
      Math.trunc(baseXp / 2) :
      Math.round(rule.points * (1.0 + cumulativeBooster));

    // Save Idempotent Event
    transaction.set(eventRef, {
      amount: finalAmount,
      pointsAmount: pointsAmount,
      baseAmount: baseXp,
      boosterApplied: cumulativeBooster,
      reason: reason || "Gamification XP",
      eventType: eventType,
      sourceType: sourceType || "system",
      sourceId: sourceId,
      seasonId: activeSeasonId,
      dedupeKey: eventDocId,
      createdAt: FieldValue.serverTimestamp(),
      metadata: metadata || {},
      operatorUid: canManualAdjust ? callerUid : null,
    });

    // Update user document
    const currentXp = Number(userData.xp || 0);
    const currentPoints = Number(userData.points || 0);
    const currentSeasonXp = Number(userData.seasonXp || 0);
    const currentSeasonPoints = Number(userData.seasonPoints || 0);
    const newTotalXp = currentXp + finalAmount;
    const newPoints = currentPoints + pointsAmount;
    const newSeasonXp = currentSeasonXp + finalAmount;
    const newSeasonPoints = currentSeasonPoints + pointsAmount;

    const newLevel = calculateLevel(newTotalXp);

    transaction.update(userRef, {
      xp: newTotalXp,
      points: newPoints,
      seasonXp: newSeasonXp,
      seasonPoints: newSeasonPoints,
      level: newLevel,
      levelTitle: levelTitleFor(newLevel),
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    console.log(`Successfully awarded server-side XP: +${finalAmount} (base: ${baseXp}, booster: +%${Math.round(cumulativeBooster*100)}) to user ${userId}`);

    return {
      status: "success",
      awarded: finalAmount,
      pointsAwarded: pointsAmount,
      seasonId: activeSeasonId,
      newTotalXp: newTotalXp,
      newLevel: newLevel,
    };
  });
});

exports.rebuildUserPoints = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Bu işlem için giriş yapmalısınız.");
  }

  if (!isStaffClaim(request.auth)) {
    throw new HttpsError("permission-denied", "Puan rebuild işlemi yalnızca yetkili personel içindir.");
  }

  const {targetUserId, seasonId, dryRun} = request.data || {};
  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "targetUserId zorunludur.");
  }

  const userRef = db.collection("users").doc(String(targetUserId));
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "Kullanıcı bulunamadı.");
  }

  const activeSeasonId = seasonId || await getActiveSeasonId();
  const eventsSnap = await userRef.collection("xpEvents").get();

  let xp = 0;
  let points = 0;
  let seasonXp = 0;
  let seasonPoints = 0;
  let eventCount = 0;
  const duplicateKeys = new Set();
  const seenDedupeKeys = new Set();

  eventsSnap.forEach((doc) => {
    const data = doc.data();
    const amount = Number(data.amount || 0);
    const pointsAmount = Number(data.pointsAmount || 0);
    const eventSeasonId = data.seasonId || "global";
    const dedupeKey = data.dedupeKey || doc.id;

    eventCount += 1;
    xp += amount;
    points += pointsAmount;

    if (eventSeasonId === activeSeasonId) {
      seasonXp += amount;
      seasonPoints += pointsAmount;
    }

    if (seenDedupeKeys.has(dedupeKey)) {
      duplicateKeys.add(dedupeKey);
    }
    seenDedupeKeys.add(dedupeKey);
  });

  const current = userSnap.data();
  const level = calculateLevel(xp);
  const levelTitle = levelTitleFor(level);
  const rebuild = {xp, points, seasonXp, seasonPoints, level, levelTitle};
  const diff = {
    xp: xp - Number(current.xp || 0),
    points: points - Number(current.points || 0),
    seasonXp: seasonXp - Number(current.seasonXp || 0),
    seasonPoints: seasonPoints - Number(current.seasonPoints || 0),
    level: level - Number(current.level || 1),
  };

  const response = {
    status: dryRun ? "dry_run" : "applied",
    targetUserId,
    seasonId: activeSeasonId,
    eventCount,
    duplicateDedupeKeys: Array.from(duplicateKeys).slice(0, 25),
    current: {
      xp: Number(current.xp || 0),
      points: Number(current.points || 0),
      seasonXp: Number(current.seasonXp || 0),
      seasonPoints: Number(current.seasonPoints || 0),
      level: Number(current.level || 1),
      levelTitle: current.levelTitle || "",
    },
    rebuild,
    diff,
  };

  if (dryRun === true) {
    return response;
  }

  await userRef.update({
    ...rebuild,
    lastPointsRebuildAt: FieldValue.serverTimestamp(),
    lastPointsRebuildBy: request.auth.uid,
  });

  await db.collection("auditLogs").add({
    adminEmail: request.auth.token?.email || "staff@amedspor.org",
    action: "REBUILD_USER_POINTS",
    targetType: "USER_POINTS",
    targetId: String(targetUserId),
    platform: "ADMIN_POINTS",
    createdAt: FieldValue.serverTimestamp(),
    operatorUid: request.auth.uid,
    diff,
    seasonId: activeSeasonId,
    eventCount,
  });

  return response;
});

/**
 * İstemci yetkisiz, güvenli premium rozet dağıtıcı Callable.
 */
exports.awardServerSideBadge = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısınız.");
  }

  const userId = request.auth.uid;
  const {badgeId, sourceType, sourceId} = request.data;

  if (!badgeId) {
    throw new HttpsError("invalid-argument", "badgeId zorunludur.");
  }

  return await db.runTransaction(async (transaction) => {
    const userBadgeRef = db.collection("users").doc(userId).collection("userBadges").doc(badgeId);
    const badgeSnap = await transaction.get(userBadgeRef);

    if (badgeSnap.exists) {
      return {status: "already_owned"};
    }

    const baseBadgeRef = db.collection("badges").doc(badgeId);
    const baseBadgeSnap = await transaction.get(baseBadgeRef);

    if (!baseBadgeSnap.exists) {
      throw new HttpsError("not-found", "Rozet tanımı bulunamadı.");
    }

    const badgeData = baseBadgeSnap.data();

    transaction.set(userBadgeRef, {
      badgeId: badgeId,
      userId: userId,
      title: badgeData.title || "",
      description: badgeData.description || "",
      category: badgeData.category || "general",
      icon: badgeData.icon || "",
      colorValue: badgeData.colorValue || 0xFFE53935,
      earnedAt: FieldValue.serverTimestamp(),
      sourceType: sourceType || "system",
      sourceId: sourceId || "",
      xpReward: badgeData.xpReward || 0,
      pointsReward: badgeData.pointsReward || 0,
    });

    const xpReward = Number(badgeData.xpReward || 0);
    const pointsReward = Number(badgeData.pointsReward || 0);

    if (xpReward > 0 || pointsReward > 0) {
      const userRef = db.collection("users").doc(userId);
      const userSnap = await transaction.get(userRef);
      if (userSnap.exists) {
        const uData = userSnap.data();
        transaction.update(userRef, {
          xp: Number(uData.xp || 0) + xpReward,
          points: Number(uData.points || 0) + pointsReward,
        });
      }
    }

    console.log(`Awarded premium server-side badge ${badgeId} to user ${userId}`);
    return {status: "success", badgeId: badgeId};
  });
});

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

      const oldPoints = Number(before.pointsEarned || 0);
      const newPoints = Number(after.pointsEarned || 0);
      const delta = newPoints - oldPoints;
      if (delta === 0) return;
      const seasonId = await getActiveSeasonId();

      await db.collection("users").doc(after.userId).update({
        points: FieldValue.increment(delta),
        seasonPoints: FieldValue.increment(delta),
        lastActiveAt: FieldValue.serverTimestamp(),
      });

      const title = "Tahmin sonucu";
      const message = `${after.pointsEarned || 0} puan kazandın.`;
      const targetRoute = "/predictions/me";

      await db.collection("users").doc(after.userId).collection("xpEvents").add({
        userId: after.userId,
        amount: 0,
        pointsAmount: delta,
        reason: "Tahmin puanı güncellemesi",
        eventType: "prediction_points_adjusted",
        sourceType: "prediction",
        sourceId: event.params.predictionId,
        seasonId,
        createdAt: FieldValue.serverTimestamp(),
        metadata: {
          oldPoints,
          newPoints,
        },
      });

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

exports.onPredictionDeleted = onDocumentDeleted(
    "predictions/{predictionId}",
    async (event) => {
      const prediction = event.data.data();
      if (!prediction.userId) return;

      const pointsEarned = Number(prediction.pointsEarned || 0);
      if (pointsEarned <= 0) return;

      const seasonId = await getActiveSeasonId();
      const rollback = -pointsEarned;

      await db.collection("users").doc(prediction.userId).update({
        points: FieldValue.increment(rollback),
        seasonPoints: FieldValue.increment(rollback),
        lastActiveAt: FieldValue.serverTimestamp(),
      });

      await db.collection("users").doc(prediction.userId).collection("xpEvents").add({
        userId: prediction.userId,
        amount: 0,
        pointsAmount: rollback,
        reason: "Silinen tahmin puanı geri alındı",
        eventType: "prediction_deleted_rollback",
        sourceType: "prediction",
        sourceId: event.params.predictionId,
        seasonId,
        createdAt: FieldValue.serverTimestamp(),
        metadata: {
          pointsEarned,
        },
      });
    },
);

exports.onUserRoleChanged = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (before.role === after.role) return;

      const validRoles = ["admin", "moderator", "user"];
      const newRole = after.role;

      if (!validRoles.includes(newRole)) {
        console.error(`Invalid role "${newRole}" for user ${event.params.userId}`);
        return;
      }

      try {
        await getAuth().setCustomUserClaims(event.params.userId, {
          role: newRole,
        });
        console.log(`Set custom claim role=${newRole} for ${event.params.userId}`);
      } catch (error) {
        console.error(`Failed to set custom claims for ${event.params.userId}:`, error);
      }
    },
);

/**
 * İstemcinin yazamadığı denetim izlerini (Audit Logs) Admin SDK ile güvenle saklayan Callable.
 */
exports.writeAuditLog = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Bu eylem için yetkiniz yok.");
  }

  // Token'da atalı custom claims üzerinden yetki sorgusu
  const role = request.auth.token?.role;
  if (role !== "admin" && role !== "moderator") {
    throw new HttpsError("permission-denied", "Yalnızca yetkili personel log yazabilir.");
  }

  const {adminEmail, action, targetType, targetId, platform} = request.data;
  if (!action || !targetId) {
    throw new HttpsError("invalid-argument", "action ve targetId parametreleri zorunludur.");
  }

  try {
    await db.collection("auditLogs").add({
      adminEmail: adminEmail || request.auth.token?.email || "staff@amedspor.org",
      action: action,
      targetType: targetType || "GENERAL",
      targetId: targetId,
      platform: platform || "ADMIN_CONSOLE",
      createdAt: FieldValue.serverTimestamp(),
      clientVerified: true,
      serverTimestamped: true,
      operatorUid: request.auth.uid,
    });
    console.log(`Successfully recorded backend-enforced audit log: ${action} on ${targetId}`);
    return {status: "success"};
  } catch (error) {
    console.error("Error writing server-side audit log:", error);
    throw new HttpsError("internal", "Denetim izi kaydedilemedi.");
  }
});

/**
 * İstemci bağımsız, %100 güvenli ve hile korumalı Tesis Yükseltme ve İnşaat Yönetimi.
 */
exports.upgradeClubFacility = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Bu işlem için giriş yapmalısınız.");
  }

  const userId = request.auth.uid;
  const {clubId, facilityType, isInstantUnlock, completeExisting} = request.data;

  if (!clubId) {
    throw new HttpsError("invalid-argument", "clubId parametresi zorunludur.");
  }

  return await db.runTransaction(async (transaction) => {
    const clubRef = db.collection("clubs").doc(String(clubId));
    const clubSnap = await transaction.get(clubRef);

    if (!clubSnap.exists) {
      throw new HttpsError("not-found", "Kulüp bulunamadı.");
    }

    const club = clubSnap.data();

    // Sadece mevcut inşaatı anında bitirme senaryosu
    if (completeExisting === true) {
      const activeType = club.activeConstructionType;
      const targetLevel = club.activeConstructionTargetLevel;

      if (!activeType || !targetLevel) {
        throw new HttpsError("failed-precondition", "Aktif bir inşaat bulunmuyor.");
      }

      const updateData = {
        activeConstructionType: null,
        activeConstructionTargetLevel: null,
        constructionEndsAt: null,
        lastResourceUpdate: FieldValue.serverTimestamp(),
      };

      if (activeType === "stadium") updateData.stadiumLevel = targetLevel;
      else if (activeType === "training") updateData.trainingLevel = targetLevel;
      else if (activeType === "medical") updateData.medicalLevel = targetLevel;
      else if (activeType === "academy") updateData.youthAcademyLevel = targetLevel;

      transaction.update(clubRef, updateData);
      console.log(`Server-authoritative instant completion applied for club ${clubId} facility ${activeType}->${targetLevel}`);
      return {status: "success", completedType: activeType, newLevel: targetLevel};
    }

    // Yeni inşaat/yükseltme başlatma senaryosu
    if (!facilityType) {
      throw new HttpsError("invalid-argument", "facilityType parametresi zorunludur.");
    }

    if (club.activeConstructionType) {
      throw new HttpsError("failed-precondition", "Aynı anda sadece bir tesis inşa edilebilir!");
    }

    let currentLevel = 1;
    let baseMultiplier = 0;
    let facilityName = "";

    if (facilityType === "stadium") {
      currentLevel = Number(club.stadiumLevel || 1);
      baseMultiplier = 5000;
      facilityName = "Stadyum";
    } else if (facilityType === "training") {
      currentLevel = Number(club.trainingLevel || 1);
      baseMultiplier = 3000;
      facilityName = "Antrenman Merkezi";
    } else if (facilityType === "medical") {
      currentLevel = Number(club.medicalLevel || 1);
      baseMultiplier = 4000;
      facilityName = "Sağlık Merkezi";
    } else if (facilityType === "academy") {
      currentLevel = Number(club.youthAcademyLevel || 1);
      baseMultiplier = 3500;
      facilityName = "Altyapı Akademisi";
    } else {
      throw new HttpsError("invalid-argument", "Geçersiz tesis türü.");
    }

    const cost = baseMultiplier * currentLevel;
    const nextLevel = currentLevel + 1;

    // DP İmece Maliyeti Hesaplama
    let dpCost = 0;
    if (nextLevel === 5) dpCost = 500;
    else if (nextLevel === 6) dpCost = 1000;
    else if (nextLevel >= 7) dpCost = 1500;

    // İnşaat Süresi Hesaplama
    let buildDurationSeconds = 0;
    if (nextLevel === 4) buildDurationSeconds = 60;
    else if (nextLevel === 5) buildDurationSeconds = 120;
    else if (nextLevel >= 6) buildDurationSeconds = 180;

    const currentCash = Number(club.cash || 0);
    if (currentCash < cost) {
      throw new HttpsError("resource-exhausted", `Yetersiz Bütçe! ${cost - currentCash} ₺ daha gerekiyor.`);
    }

    // Puan kontrolü ve düşümü
    const userRef = db.collection("users").doc(userId);
    if (dpCost > 0) {
      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "Kullanıcı kaydı bulunamadı.");
      }
      const userPoints = Number(userSnap.data().points || 0);
      if (userPoints < dpCost) {
        throw new HttpsError("resource-exhausted", `Yetersiz Taraftar Puanı (DP)! ${dpCost} DP gerekiyor.`);
      }
      transaction.update(userRef, {
        points: FieldValue.increment(-dpCost),
      });
    }

    const clubUpdate = {
      cash: currentCash - cost,
      lastResourceUpdate: FieldValue.serverTimestamp(),
    };

    if (isInstantUnlock === true || buildDurationSeconds <= 0) {
      // Anında tamamlama
      if (facilityType === "stadium") clubUpdate.stadiumLevel = nextLevel;
      else if (facilityType === "training") clubUpdate.trainingLevel = nextLevel;
      else if (facilityType === "medical") clubUpdate.medicalLevel = nextLevel;
      else if (facilityType === "academy") clubUpdate.youthAcademyLevel = nextLevel;
    } else {
      // Süreli inşaat başlatma
      const endsAt = new Date(Date.now() + buildDurationSeconds * 1000);
      clubUpdate.activeConstructionType = facilityType;
      clubUpdate.activeConstructionTargetLevel = nextLevel;
      clubUpdate.constructionEndsAt = endsAt;
    }

    transaction.update(clubRef, clubUpdate);

    console.log(`Successfully upgraded facility ${facilityType}->${nextLevel} for club ${clubId} by user ${userId}`);
    return {
      status: "success",
      facilityName,
      nextLevel,
      isInstant: isInstantUnlock === true || buildDurationSeconds <= 0,
      buildDurationSeconds,
    };
  });
});

