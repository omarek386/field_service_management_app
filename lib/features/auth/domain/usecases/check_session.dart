import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckSession implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  CheckSession(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) {
    return repository.getCachedSession();
  }
}
