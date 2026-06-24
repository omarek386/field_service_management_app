import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/jobs_repository.dart';
import '../datasources/jobs_local_data_source.dart';
import '../datasources/jobs_remote_data_source.dart';
import '../models/job_model.dart';

class JobsRepositoryImpl implements JobsRepository {
  final JobsRemoteDataSource remoteDataSource;
  final JobsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  JobsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Job>>> getJobs(String technicianId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteJobs = await remoteDataSource.getJobs(technicianId);
        await localDataSource.cacheJobs(remoteJobs);
        return Right(remoteJobs);
      } on ServerException catch (e) {
        // Fallback to cache if server is down
        try {
          final localJobs = await localDataSource.getCachedJobs();
          return Right(localJobs);
        } catch (_) {
          return Left(ServerFailure(e.message));
        }
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final localJobs = await localDataSource.getCachedJobs();
        return Right(localJobs);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, Job>> updateJobStatus(String jobId, String status) async {
    // Read local jobs list
    List<JobModel> cachedJobs = [];
    try {
      cachedJobs = await localDataSource.getCachedJobs();
    } catch (_) {}

    // Find and update status in local cache list first to ensure local UI feels immediate
    JobModel? targetJob;
    final updatedList = cachedJobs.map((j) {
      if (j.id == jobId) {
        targetJob = JobModel(
          id: j.id,
          customerName: j.customerName,
          serviceType: j.serviceType,
          description: j.description,
          status: status, // updated
          assignedTechnicianId: j.assignedTechnicianId,
          serviceDate: j.serviceDate,
          customerPhone: j.customerPhone,
          serviceAddress: j.serviceAddress,
        );
        return targetJob!;
      }
      return j;
    }).toList();

    if (targetJob != null) {
      await localDataSource.cacheJobs(updatedList);
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteUpdatedJob = await remoteDataSource.updateJobStatus(jobId, status);
        return Right(remoteUpdatedJob);
      } on ServerException catch (e) {
        // If server fails but local cache updated, we can return the local update and log the sync failure
        return targetJob != null
            ? Right(targetJob!)
            : Left(ServerFailure(e.message));
      } catch (e) {
        return targetJob != null
            ? Right(targetJob!)
            : Left(ServerFailure(e.toString()));
      }
    } else {
      // Offline support: return local update directly, it will be uploaded during synchronization
      if (targetJob != null) {
        return Right(targetJob!);
      }
      return const Left(CacheFailure('Job not found in local cache to update offline.'));
    }
  }
}
