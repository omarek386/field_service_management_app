import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

abstract class UseCase<TypeParam, Params> {
  Future<Either<Failure, TypeParam>> call(Params params);
}

class NoParams {
  const NoParams();
}
