import 'package:cloud_firestore/cloud_firestore.dart';

class ResetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Projeyi canlıya almadan önce tüm verileri temizler.
  Future<void> wipeAllData() async {
    final collections = [
      'players',
      'matches',
      'predictions',
      'missions',
      'posts',
      'lineups',
      'reports',
      'notifications',
      'chatRooms',
      'badges',
      'seasons',
      'gamificationRules',
      'feedback',
      'errorReports',
      'auditLogs',
    ];

    for (final collectionName in collections) {
      await _deleteCollection(collectionName);
    }
  }

  Future<void> resetAndSeedPlayers() async {
    // 1. Önce mevcut oyuncuları sil
    await _deleteCollection('players');

    // 2. Yeni kadroyu seed et
    // Not: Circular dependency olmaması için seedService'i burada local olarak import veya çağrı ile kullanabiliriz.
    // Ancak daha kolayı SeedService'i Admin panelinde çağırmaktır.
    // Burada sadece silme işlemini bırakıp ismini daha net yapalım.
  }

  Future<void> wipePlayersOnly() async {
    await _deleteCollection('players');
  }

  Future<void> _deleteCollection(String collectionPath) async {
    final collection = _firestore.collection(collectionPath);
    final snapshots = await collection.get();

    // Web uyumlu silme işlemi (batch kullanarak)
    final batch = _firestore.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    if (snapshots.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
