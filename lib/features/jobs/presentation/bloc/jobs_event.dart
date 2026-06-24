import 'package:equatable/equatable.dart';

abstract class JobsEvent extends Equatable {
  const JobsEvent();

  @override
  List<Object?> get props => [];
}

class FetchJobsEvent extends JobsEvent {
  final String technicianId;

  const FetchJobsEvent(this.technicianId);

  @override
  List<Object?> get props => [technicianId];
}

class UpdateJobStatusEvent extends JobsEvent {
  final String jobId;
  final String status;

  const UpdateJobStatusEvent({required this.jobId, required this.status});

  @override
  List<Object?> get props => [jobId, status];
}
