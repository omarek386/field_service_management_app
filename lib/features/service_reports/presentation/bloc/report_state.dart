import 'package:equatable/equatable.dart';
import '../../domain/entities/service_report.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportSubmitting extends ReportState {}

class ReportSubmitSuccess extends ReportState {
  final ServiceReport report;

  const ReportSubmitSuccess(this.report);

  @override
  List<Object?> get props => [report];
}

class ReportSubmitFailure extends ReportState {
  final String message;

  const ReportSubmitFailure(this.message);

  @override
  List<Object?> get props => [message];
}
