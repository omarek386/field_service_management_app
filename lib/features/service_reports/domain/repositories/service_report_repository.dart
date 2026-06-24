import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_report.dart';

abstract class ServiceReportRepository {
  Future<Either<Failure, ServiceReport>> submitReport(ServiceReport report);
}
