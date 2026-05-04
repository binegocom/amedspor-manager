import '../models/report_model.dart';
import '../services/firebase/firebase_providers.dart';

class ReportRepository {
  Future<void> createReport(ReportModel report) async {
    await firestoreService.reports.doc(report.id).set(report.toMap());
  }

  Stream<List<ReportModel>> watchUserReports(String userId) {
    return firestoreService.reports
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ReportModel>> watchAllReports() {
    return firestoreService.reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}