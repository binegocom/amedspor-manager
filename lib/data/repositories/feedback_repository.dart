import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_feedback_model.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback(UserFeedbackModel feedback) async {
    await _firestore.collection('feedback').add(feedback.toMap());
  }

  Stream<List<UserFeedbackModel>> getFeedbackStream({String? status}) {
    Query query = _firestore.collection('feedback').orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserFeedbackModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> updateFeedbackStatus(String id, String status) async {
    await _firestore.collection('feedback').doc(id).update({
      'status': status,
    });
  }
}
