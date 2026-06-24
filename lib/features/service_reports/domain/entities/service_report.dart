import 'package:equatable/equatable.dart';

class ServiceReport extends Equatable {
  final String id;
  final String jobId;
  final String findings;
  final String actionsTaken;
  final String completionNotes;
  final DateTime timestamp;
  final String? gpsCoordinates;
  final String? evidenceImagePath;

  const ServiceReport({
    required this.id,
    required this.jobId,
    required this.findings,
    required this.actionsTaken,
    required this.completionNotes,
    required this.timestamp,
    this.gpsCoordinates,
    this.evidenceImagePath,
  });

  @override
  List<Object?> get props => [
        id,
        jobId,
        findings,
        actionsTaken,
        completionNotes,
        timestamp,
        gpsCoordinates,
        evidenceImagePath,
      ];
}
