import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/firebase/firebase_providers.dart';
import '../../data/models/audit_log_model.dart';

class AuditLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logAction({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) async {
    try {
      final user = authService.currentUser;
      if (user == null) return;

      final log = AuditLogModel(
        id: '',
        adminId: user.uid,
        adminEmail: user.email ?? 'unknown',
        action: action,
        targetType: targetType,
        targetId: targetId,
        before: before,
        after: after,
        createdAt: DateTime.now(),
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );

      await _firestore.collection('auditLogs').add(log.toMap());
    } catch (e) {
      if (kDebugMode) print('Error recording audit log: $e');
    }
  }
}
