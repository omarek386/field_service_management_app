import '../../domain/entities/service_report.dart';

class ServiceReportModel extends ServiceReport {
  const ServiceReportModel({
    required super.id,
    required super.jobId,
    required super.findings,
    required super.actionsTaken,
    required super.completionNotes,
    required super.timestamp,
    super.gpsCoordinates,
    super.evidenceImagePath,
  });

  factory ServiceReportModel.fromJson(Map<String, dynamic> json) {
    dynamic rawTime = json['timestamp'];
    DateTime parsedTime;
    if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    } else {
      parsedTime = DateTime.now();
    }

    return ServiceReportModel(
      id: json['id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      findings: json['findings'] as String? ?? '',
      actionsTaken: json['actionsTaken'] as String? ?? '',
      completionNotes: json['completionNotes'] as String? ?? '',
      timestamp: parsedTime,
      gpsCoordinates: json['gpsCoordinates'] as String?,
      evidenceImagePath: json['evidenceImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'findings': findings,
      'actionsTaken': actionsTaken,
      'completionNotes': completionNotes,
      'timestamp': timestamp.toIso8601String(),
      'gpsCoordinates': gpsCoordinates,
      'evidenceImagePath': evidenceImagePath,
    };
  }

  factory ServiceReportModel.fromEntity(ServiceReport report) {
    return ServiceReportModel(
      id: report.id,
      jobId: report.jobId,
      findings: report.findings,
      actionsTaken: report.actionsTaken,
      completionNotes: report.completionNotes,
      timestamp: report.timestamp,
      gpsCoordinates: report.gpsCoordinates,
      evidenceImagePath: report.evidenceImagePath,
    );
  }
}
