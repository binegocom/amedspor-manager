import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AuditLogRepository {
  Future<QuerySnapshot> getAuditLogsPaginated({
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('auditLogs')
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
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'writeAuditLog',
      );
      await callable.call({
        'adminEmail': adminEmail,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'platform': platform ?? 'ADMIN_CONSOLE',
      });
    } catch (e) {
      debugPrint('Mandatory backend-enforced audit log trigger error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchRecentLogs({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection('auditLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
