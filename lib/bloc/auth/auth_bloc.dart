import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:blue_ribbon/data/repositories/authentication_repository.dart';
import 'package:blue_ribbon/data/models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationRepository _authenticationRepository;

  AuthBloc({required AuthenticationRepository authenticationRepository})
      : _authenticationRepository = authenticationRepository,
        super(const AuthState.unknown()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    return emit.onEach(
      _authenticationRepository.status,
      onData: (status) {
        switch (status) {
          case AuthenticationStatus.unauthenticated:
            emit(const AuthState.unauthenticated());
            break;
          case AuthenticationStatus.authenticated:
            final user = _authenticationRepository.currentUser;
            emit(
              user != null
                  ? AuthState.authenticated(user)
                  : const AuthState.unauthenticated(),
            );
            break;
          case AuthenticationStatus.unknown:
            emit(const AuthState.unknown());
            break;
        }
      },
      onError: (_, __) => emit(const AuthState.unauthenticated()),
    );
  }

  void _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    _authenticationRepository.logOut();
  }
}
