import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      contactNumber: params.contactNumber,
      role: params.role,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String fullName;
  final String contactNumber;
  final String role;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.contactNumber,
    required this.role,
  });

  @override
  List<Object> get props => [email, password, fullName, contactNumber, role];
}
