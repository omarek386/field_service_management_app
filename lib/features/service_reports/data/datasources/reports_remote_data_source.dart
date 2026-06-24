import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/service_report_model.dart';

abstract class ReportsRemoteDataSource {
  Future<void> submitReport(ServiceReportModel report);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String _reportsCollection = 'service_reports';
  static const String _jobsCollection = 'jobs';

  ReportsRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> submitReport(ServiceReportModel report) async {
    try {
      final batch = firestore.batch();

      // Submit report document
      final reportRef = firestore.collection(_reportsCollection).doc(report.id);
      batch.set(reportRef, report.toJson());

      // Set corresponding job status to completed in Firestore
      final jobRef = firestore.collection(_jobsCollection).doc(report.jobId);
      batch.update(jobRef, {'status': 'completed'});

      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
