import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/service_report.dart';
import '../repositories/service_report_repository.dart';

class SubmitReport implements UseCase<ServiceReport, ServiceReport> {
  final ServiceReportRepository repository;

  SubmitReport(this.repository);

  @override
  Future<Either<Failure, ServiceReport>> call(ServiceReport report) {
    return repository.submitReport(report);
  }
}
