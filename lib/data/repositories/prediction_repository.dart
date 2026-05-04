import '../models/prediction_model.dart';
import '../services/firebase/firebase_providers.dart';

class PredictionRepository {
  Future<void> savePrediction(PredictionModel prediction) async {
    await firestoreService.predictions
        .doc(prediction.id)
        .set(prediction.toMap());
  }

  Stream<List<PredictionModel>> watchUserPredictions(String userId) {
    return firestoreService.predictions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PredictionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}