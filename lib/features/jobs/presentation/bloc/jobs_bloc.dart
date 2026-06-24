import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_jobs.dart';
import '../../domain/usecases/update_job_status.dart';
import 'jobs_event.dart';
import 'jobs_state.dart';

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final GetJobs getJobs;
  final UpdateJobStatus updateJobStatus;

  JobsBloc({
    required this.getJobs,
    required this.updateJobStatus,
  }) : super(JobsInitial()) {
    on<FetchJobsEvent>(_onFetchJobs);
    on<UpdateJobStatusEvent>(_onUpdateJobStatus);
  }

  Future<void> _onFetchJobs(FetchJobsEvent event, Emitter<JobsState> emit) async {
    emit(JobsLoading());
    final result = await getJobs(event.technicianId);
    result.fold(
      (failure) => emit(JobsError(failure.message)),
      (jobs) => emit(JobsLoaded(jobs)),
    );
  }

  Future<void> _onUpdateJobStatus(UpdateJobStatusEvent event, Emitter<JobsState> emit) async {
    // Keep local state in loaded to update immediately if possible, or transition
    final currentState = state;
    if (currentState is JobsLoaded) {
      final updatedJobs = currentState.jobs.map((job) {
        return job.id == event.jobId ? job.copyWith(status: event.status) : job;
      }).toList();
      emit(JobsLoaded(updatedJobs));
    }

    final result = await updateJobStatus(UpdateJobStatusParams(
      jobId: event.jobId,
      status: event.status,
    ));

    // If result was failure and we emitted an optimistic update, we can fetch again or emit error.
    // However, since updateJobStatus supports offline cache fallbacks, it usually succeeds.
    result.fold(
      (failure) {
        // Fetch jobs again to revert optimistic update
        if (currentState is JobsLoaded) {
          emit(JobsError(failure.message));
        }
      },
      (updatedJob) {
        // The list is already updated optimistically above, but we can do a formal refresh if needed
      },
    );
  }
}
