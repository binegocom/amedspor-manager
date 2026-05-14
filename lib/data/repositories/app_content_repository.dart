import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_content_model.dart';
import '../services/firebase/firebase_providers.dart';
import 'audit_log_repository.dart';

class AppContentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppContentModel> getContent(String id) async {
    try {
      final doc = await _firestore.collection('appContent').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return AppContentModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      debugPrint('İçerik yükleme hatası ($id): $e');
    }

    if (id == 'onboarding') {
      return AppContentModel.defaultOnboarding();
    }

    return AppContentModel(
      id: id,
      title: 'Yeni İçerik Blok',
      category: 'page',
      items: const [],
      updatedAt: DateTime.now(),
    );
  }

  Stream<AppContentModel> watchContent(String id) {
    return _firestore.collection('appContent').doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppContentModel.fromMap(doc.id, doc.data()!);
      }
      if (id == 'onboarding') {
        return AppContentModel.defaultOnboarding();
      }
      return AppContentModel(
        id: id,
        title: 'Yeni İçerik Blok',
        category: 'page',
        items: const [],
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<List<AppContentModel>> getAllContents() async {
    try {
      final snapshot = await _firestore.collection('appContent').get();
      final list = snapshot.docs
          .map((doc) => AppContentModel.fromMap(doc.id, doc.data()))
          .toList();

      if (!list.any((content) => content.id == 'onboarding')) {
        list.insert(0, AppContentModel.defaultOnboarding());
      }
      return list;
    } catch (e) {
      debugPrint('Tüm içerikleri çekme hatası: $e');
      return [AppContentModel.defaultOnboarding()];
    }
  }

  Future<void> saveContent(AppContentModel content) async {
    try {
      await _firestore
          .collection('appContent')
          .doc(content.id)
          .set(content.toMap(), SetOptions(merge: true));

      final currentEmail =
          authService.currentUser?.email ?? 'admin@amedspor.org';
      await AuditLogRepository().logAction(
        adminEmail: currentEmail,
        action: 'UPDATE_APP_CONTENT (${content.id})',
        targetType: 'APP_CONTENT_CMS',
        targetId: content.id,
        platform: 'ADMIN_CONSOLE',
      );
    } catch (e) {
      debugPrint('İçerik kaydetme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteContent(String id) async {
    if (id == 'onboarding') {
      throw Exception(
        'Sistem kök karşılama slaytları silinemez, sadece pasife alınabilir.',
      );
    }
    try {
      await _firestore.collection('appContent').doc(id).delete();

      final currentEmail =
          authService.currentUser?.email ?? 'admin@amedspor.org';
      await AuditLogRepository().logAction(
        adminEmail: currentEmail,
        action: 'DELETE_APP_CONTENT ($id)',
        targetType: 'APP_CONTENT_CMS',
        targetId: id,
        platform: 'ADMIN_CONSOLE',
      );
    } catch (e) {
      debugPrint('İçerik silme hatası: $e');
      rethrow;
    }
  }
}
