import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';

// --- Events ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final UserRole role;

  const LoginRequested(this.username, this.role);

  @override
  List<Object?> get props => [username, role];
}

class LogoutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String username;
  final UserRole role;

  const AuthAuthenticated(this.username, this.role);

  @override
  List<Object?> get props => [username, role];
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>((event, emit) {
      emit(AuthAuthenticated(event.username, event.role));
    });

    on<LogoutRequested>((event, emit) {
      emit(AuthUnauthenticated());
    });
  }
}
