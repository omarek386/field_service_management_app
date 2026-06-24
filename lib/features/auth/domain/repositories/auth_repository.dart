import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String role,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCachedSession();
}
