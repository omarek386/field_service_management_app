import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/job_model.dart';

abstract class JobsRemoteDataSource {
  Future<List<JobModel>> getJobs(String technicianId);
  Future<JobModel> updateJobStatus(String jobId, String status);
}

class JobsRemoteDataSourceImpl implements JobsRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String _jobsCollection = 'jobs';

  JobsRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<JobModel>> getJobs(String technicianId) async {
    try {
      final snapshot = await firestore
          .collection(_jobsCollection)
          .where('assignedTechnicianId', isEqualTo: technicianId)
          .get();

      if (snapshot.docs.isEmpty) {
        // Mock seeding if Firestore has no jobs for this technician.
        // This ensures the dashboard doesn't look empty and is ready to show.
        final List<JobModel> mockJobs = [
          JobModel(
            id: 'job_001',
            customerName: 'Ahmad Al-Fayed',
            serviceType: 'Internet Fiber Installation',
            description: 'Install high-speed fiber connection and configure router.',
            status: 'pending',
            assignedTechnicianId: technicianId,
            serviceDate: DateTime.now().add(const Duration(hours: 2)),
            customerPhone: '+962-79-123-4567',
            serviceAddress: 'Building 14, 5th Circle, Amman, Jordan',
          ),
          JobModel(
            id: 'job_002',
            customerName: 'John Doe',
            serviceType: 'AC Maintenance',
            description: 'Clean filters, check refrigerant levels, and troubleshoot fan noise.',
            status: 'accepted',
            assignedTechnicianId: technicianId,
            serviceDate: DateTime.now().subtract(const Duration(hours: 4)),
            customerPhone: '+1-555-0199',
            serviceAddress: '128 Birch Lane, San Jose, CA',
          ),
          JobModel(
            id: 'job_003',
            customerName: 'Sarah Smith',
            serviceType: 'Washing Machine Repair',
            description: 'Machine is not draining. Inspect pump and hoses.',
            status: 'completed',
            assignedTechnicianId: technicianId,
            serviceDate: DateTime.now().subtract(const Duration(days: 1)),
            customerPhone: '+1-555-0254',
            serviceAddress: '439 Maplewood Drive, Austin, TX',
          ),
        ];

        // Seed to firestore so it is persistent
        for (var job in mockJobs) {
          await firestore.collection(_jobsCollection).doc(job.id).set(job.toJson());
        }

        return mockJobs;
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JobModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<JobModel> updateJobStatus(String jobId, String status) async {
    try {
      await firestore.collection(_jobsCollection).doc(jobId).update({'status': status});
      final updatedDoc = await firestore.collection(_jobsCollection).doc(jobId).get();
      if (updatedDoc.exists && updatedDoc.data() != null) {
        final data = updatedDoc.data()!;
        data['id'] = jobId;
        return JobModel.fromJson(data);
      } else {
        throw const ServerException('Failed to retrieve updated job document.');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
