import 'package:equatable/equatable.dart';
import '../../domain/entities/service_report.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReportEvent extends ReportEvent {
  final ServiceReport report;

  const SubmitReportEvent(this.report);

  @override
  List<Object?> get props => [report];
}
