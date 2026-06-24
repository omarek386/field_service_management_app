import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job.dart';
import '../repositories/jobs_repository.dart';

class GetJobs implements UseCase<List<Job>, String> {
  final JobsRepository repository;

  GetJobs(this.repository);

  @override
  Future<Either<Failure, List<Job>>> call(String technicianId) {
    return repository.getJobs(technicianId);
  }
}
