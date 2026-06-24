import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/submit_report.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final SubmitReport submitReport;

  ReportBloc({required this.submitReport}) : super(ReportInitial()) {
    on<SubmitReportEvent>(_onSubmitReport);
  }

  Future<void> _onSubmitReport(SubmitReportEvent event, Emitter<ReportState> emit) async {
    emit(ReportSubmitting());
    final result = await submitReport(event.report);
    result.fold(
      (failure) => emit(ReportSubmitFailure(failure.message)),
      (report) => emit(ReportSubmitSuccess(report)),
    );
  }
}
