import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorReportRepository {
  Future<QuerySnapshot> getErrorReportsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = FirebaseFirestore.instance.collection('errorReports')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  Future<void> updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('errorReports').doc(id).update({
      'status': status,
    });
  }
}
