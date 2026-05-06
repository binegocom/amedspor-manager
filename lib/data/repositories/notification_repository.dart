import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../services/firebase/firebase_providers.dart';

class NotificationRepository {
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return firestoreService.notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> createNotification(NotificationModel notification) async {
    await firestoreService.notifications
        .doc(notification.id)
        .set(notification.toMap());
  }

  Future<void> markAsRead(String notificationId) async {
    await firestoreService.notifications.doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await firestoreService.notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}
