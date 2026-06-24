import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final String id;
  final String customerName;
  final String serviceType;
  final String description;
  final String status; // 'pending', 'accepted', 'in_progress', 'completed', 'rejected'
  final String assignedTechnicianId;
  final DateTime serviceDate;
  final String customerPhone;
  final String serviceAddress;

  const Job({
    required this.id,
    required this.customerName,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.assignedTechnicianId,
    required this.serviceDate,
    required this.customerPhone,
    required this.serviceAddress,
  });

  @override
  List<Object?> get props => [
        id,
        customerName,
        serviceType,
        description,
        status,
        assignedTechnicianId,
        serviceDate,
        customerPhone,
        serviceAddress,
      ];

  Job copyWith({
    String? id,
    String? customerName,
    String? serviceType,
    String? description,
    String? status,
    String? assignedTechnicianId,
    DateTime? serviceDate,
    String? customerPhone,
    String? serviceAddress,
  }) {
    return Job(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      serviceDate: serviceDate ?? this.serviceDate,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceAddress: serviceAddress ?? this.serviceAddress,
    );
  }
}
