part of 'login_bloc.dart';

enum LoginStatus {
  initial,
  submissionInProgress,
  submissionSuccess,
  submissionFailure
}

final class LoginState extends Equatable {
  final String email;
  final String password;
  final LoginStatus status;
  final String? errorMessage;
  final bool obscurePassword;

  bool get isValid => email.isNotEmpty && password.isNotEmpty;

  const LoginState({
    this.email = 'test@example.com',
    this.password = 'samsung@135',
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.obscurePassword = true,
  });

  LoginState copyWith({
    String? email,
    String? password,
    LoginStatus? status,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }

  @override
  List<Object?> get props =>
      [email, password, status, errorMessage, obscurePassword];
}
