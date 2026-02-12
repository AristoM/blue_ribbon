import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:blue_ribbon/data/repositories/authentication_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthenticationRepository _authenticationRepository;

  LoginBloc({
    required AuthenticationRepository authenticationRepository,
  })  : _authenticationRepository = authenticationRepository,
        super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
  }

  void _onPasswordVisibilityToggled(
      LoginPasswordVisibilityToggled event, Emitter<LoginState> emit) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      email: event.email,
      status: LoginStatus.initial,
      errorMessage: null,
    ));
  }

  void _onPasswordChanged(
      LoginPasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      password: event.password,
      status: LoginStatus.initial,
      errorMessage: null,
    ));
  }

  Future<void> _onSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    if (!state.isValid) return;

    emit(state.copyWith(status: LoginStatus.submissionInProgress));
    try {
      await _authenticationRepository.logIn(
        email: state.email,
        password: state.password,
      );
      emit(state.copyWith(status: LoginStatus.submissionSuccess));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.submissionFailure,
        errorMessage: e.toString(),
      ));
    }
  }
}
