import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String contactNumber;
  final String role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.contactNumber,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, contactNumber, role];
}
