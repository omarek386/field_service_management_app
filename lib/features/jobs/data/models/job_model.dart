import '../../domain/entities/job.dart';

class JobModel extends Job {
  const JobModel({
    required super.id,
    required super.customerName,
    required super.serviceType,
    required super.description,
    required super.status,
    required super.assignedTechnicianId,
    required super.serviceDate,
    required super.customerPhone,
    required super.serviceAddress,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Parse service date. It could be stored as Firestore Timestamp or ISO string.
    dynamic rawDate = json['serviceDate'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now(); // Fallback
    }

    return JobModel(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      assignedTechnicianId: json['assignedTechnicianId'] as String? ?? '',
      serviceDate: parsedDate,
      customerPhone: json['customerPhone'] as String? ?? '',
      serviceAddress: json['serviceAddress'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'serviceType': serviceType,
      'description': description,
      'status': status,
      'assignedTechnicianId': assignedTechnicianId,
      'serviceDate': serviceDate.toIso8601String(),
      'customerPhone': customerPhone,
      'serviceAddress': serviceAddress,
    };
  }

  factory JobModel.fromEntity(Job job) {
    return JobModel(
      id: job.id,
      customerName: job.customerName,
      serviceType: job.serviceType,
      description: job.description,
      status: job.status,
      assignedTechnicianId: job.assignedTechnicianId,
      serviceDate: job.serviceDate,
      customerPhone: job.customerPhone,
      serviceAddress: job.serviceAddress,
    );
  }
}
