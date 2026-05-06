import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../services/firebase/firebase_providers.dart';

class QuestionRepository {
  Future<void> addQuestion(QuestionModel question) async {
    // Deactivate all other questions first if this one is active
    if (question.active) {
      final activeQuestions = await firestoreService.questions
          .where('active', isEqualTo: true)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in activeQuestions.docs) {
        batch.update(doc.reference, {'active': false});
      }
      await batch.commit();
    }
    
    await firestoreService.questions.doc(question.id).set(question.toMap());
  }

  Future<void> updateQuestion(QuestionModel question) async {
    await firestoreService.questions.doc(question.id).update(question.toMap());
  }

  Future<void> deleteQuestion(String id) async {
    await firestoreService.questions.doc(id).delete();
  }

  Stream<List<QuestionModel>> watchQuestions() {
    return firestoreService.questions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<QuestionModel?> watchActiveQuestion() {
    return firestoreService.questions
        .where('active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return QuestionModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    });
  }

  Future<void> vote(String questionId, bool isOptionA) async {
    await firestoreService.questions.doc(questionId).update({
      isOptionA ? 'votesA' : 'votesB': FieldValue.increment(1),
    });
  }
}
