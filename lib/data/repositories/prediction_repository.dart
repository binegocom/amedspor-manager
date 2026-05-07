import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prediction_model.dart';
import '../services/firebase/firebase_providers.dart';

class PredictionRepository {
  Future<void> savePrediction(PredictionModel prediction) async {
    await firestoreService.predictions
        .doc(prediction.id)
        .set(prediction.toMap());
  }

  Stream<List<PredictionModel>> watchUserPredictions(String userId, {int limit = 30}) {
    return firestoreService.predictions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PredictionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<QuerySnapshot> getPredictionsSnapshotPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = firestoreService.predictions
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }
}
