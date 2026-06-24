import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/service_report.dart';
import '../../domain/repositories/service_report_repository.dart';
import '../datasources/reports_local_data_source.dart';
import '../datasources/reports_remote_data_source.dart';
import '../models/service_report_model.dart';

class ServiceReportRepositoryImpl implements ServiceReportRepository {
  final ReportsRemoteDataSource remoteDataSource;
  final ReportsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ServiceReportRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ServiceReport>> submitReport(ServiceReport report) async {
    final reportModel = ServiceReportModel.fromEntity(report);

    // Save report to cache first to ensure it's never lost offline
    try {
      await localDataSource.cacheReport(reportModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }

    // Attempt remote submission
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.submitReport(reportModel);
        await localDataSource.markAsSynced(reportModel.id);
        return Right(reportModel);
      } on ServerException catch (_) {
        // Since it's stored locally, we return the cached report to user so UI updates,
        // and it remains in the local unsynced queue to sync later.
        return Right(reportModel);
      } catch (_) {
        return Right(reportModel);
      }
    } else {
      // Offline: Report saved locally in queue. Return success.
      return Right(reportModel);
    }
  }
}
