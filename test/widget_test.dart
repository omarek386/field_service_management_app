import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:field_service_management_app/core/error/failures.dart';
import 'package:field_service_management_app/features/auth/domain/entities/user.dart';
import 'package:field_service_management_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:field_service_management_app/features/auth/domain/usecases/login_user.dart';
import 'package:field_service_management_app/features/jobs/domain/entities/job.dart';
import 'package:field_service_management_app/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:field_service_management_app/features/jobs/domain/usecases/get_jobs.dart';
import 'package:field_service_management_app/features/service_reports/domain/entities/service_report.dart';
import 'package:field_service_management_app/features/service_reports/domain/repositories/service_report_repository.dart';
import 'package:field_service_management_app/features/service_reports/domain/usecases/submit_report.dart';

// Mock implementations
class MockAuthRepository implements AuthRepository {
  final User mockUser;
  MockAuthRepository(this.mockUser);

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (email == mockUser.email) {
      return Right(mockUser);
    }
    return const Left(AuthFailure('Invalid credentials'));
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String role,
  }) async {
    return Right(mockUser);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User?>> getCachedSession() async {
    return Right(mockUser);
  }
}

class MockJobsRepository implements JobsRepository {
  final List<Job> mockJobs;
  MockJobsRepository(this.mockJobs);

  @override
  Future<Either<Failure, List<Job>>> getJobs(String technicianId) async {
    return Right(mockJobs.where((j) => j.assignedTechnicianId == technicianId).toList());
  }

  @override
  Future<Either<Failure, Job>> updateJobStatus(String jobId, String status) async {
    final job = mockJobs.firstWhere((j) => j.id == jobId);
    return Right(job.copyWith(status: status));
  }
}

class MockServiceReportRepository implements ServiceReportRepository {
  @override
  Future<Either<Failure, ServiceReport>> submitReport(ServiceReport report) async {
    return Right(report);
  }
}

void main() {
  group('Clean Architecture Use Cases Unit Tests', () {
    const tUser = User(
      id: 'tech_123',
      fullName: 'Omar Fayed',
      email: 'omar@teyzix.com',
      contactNumber: '+962-79-123-4567',
      role: 'technician',
    );

    final tJobs = [
      Job(
        id: 'job_001',
        customerName: 'Ahmad Al-Fayed',
        serviceType: 'Internet Fiber Installation',
        description: 'Install fiber connection.',
        status: 'pending',
        assignedTechnicianId: 'tech_123',
        serviceDate: DateTime.now(),
        customerPhone: '+962-79-111-2222',
        serviceAddress: 'Amman, Jordan',
      ),
      Job(
        id: 'job_002',
        customerName: 'John Doe',
        serviceType: 'AC Maintenance',
        description: 'Clean filter.',
        status: 'accepted',
        assignedTechnicianId: 'tech_other',
        serviceDate: DateTime.now(),
        customerPhone: '+1-555-0199',
        serviceAddress: 'San Jose, CA',
      ),
    ];

    test('LoginUser usecase should return User when login is successful', () async {
      // Arrange
      final mockAuthRepository = MockAuthRepository(tUser);
      final loginUseCase = LoginUser(mockAuthRepository);

      // Act
      final result = await loginUseCase(const LoginParams(email: 'omar@teyzix.com', password: 'password123'));

      // Assert
      expect(result, const Right(tUser));
    });

    test('GetJobs usecase should return assigned jobs for the given technician', () async {
      // Arrange
      final mockJobsRepository = MockJobsRepository(tJobs);
      final getJobsUseCase = GetJobs(mockJobsRepository);

      // Act
      final result = await getJobsUseCase('tech_123');

      // Assert
      result.fold(
        (failure) => fail('Should not fail'),
        (jobs) {
          expect(jobs.length, 1);
          expect(jobs.first.id, 'job_001');
        },
      );
    });

    test('SubmitReport usecase should submit service report and return completed report details', () async {
      // Arrange
      final mockReportRepository = MockServiceReportRepository();
      final submitReportUseCase = SubmitReport(mockReportRepository);
      final tReport = ServiceReport(
        id: 'rep_001',
        jobId: 'job_001',
        findings: 'Fiber cable damaged in street cabinet',
        actionsTaken: 'Spliced damaged fiber core and completed testing',
        completionNotes: 'All services recovered.',
        timestamp: DateTime.now(),
      );

      // Act
      final result = await submitReportUseCase(tReport);

      // Assert
      expect(result, Right(tReport));
    });
  });
}
