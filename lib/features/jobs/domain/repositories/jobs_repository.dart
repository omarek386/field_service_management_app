import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/job.dart';

abstract class JobsRepository {
  Future<Either<Failure, List<Job>>> getJobs(String technicianId);
  Future<Either<Failure, Job>> updateJobStatus(String jobId, String status);
}
