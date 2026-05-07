import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogRepository {
  Future<QuerySnapshot> getAuditLogsPaginated({
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = FirebaseFirestore.instance.collection('auditLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  Future<void> logAction({
    required String adminEmail,
    required String action,
    required String targetType,
    required String targetId,
    String? platform,
  }) async {
    await FirebaseFirestore.instance.collection('auditLogs').add({
      'adminEmail': adminEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchRecentLogs({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection('auditLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
