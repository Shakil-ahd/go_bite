import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';

// ─── Auth Method ───
enum AuthMethod { phone, email }

// ─── Events ───
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignupRequested extends AuthEvent {
  final UserProfile profile;
  final AuthMethod method;

  const SignupRequested({
    required this.profile,
    required this.method,
  });

  @override
  List<Object?> get props => [profile, method];
}

class LoginRequested extends AuthEvent {
  final String username;

  const LoginRequested(this.username);

  @override
  List<Object?> get props => [username];
}

class UpdateProfile extends AuthEvent {
  final UserProfile profile;
  const UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class LogoutRequested extends AuthEvent {}

// ─── States ───
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String username;
  final UserProfile profile;

  const AuthAuthenticated(this.username, this.profile);

  @override
  List<Object?> get props => [username, profile];
}

// ─── Bloc ───
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<SignupRequested>((event, emit) {
      emit(AuthAuthenticated(
        event.profile.fullName,
        event.profile,
      ));
    });

    on<LoginRequested>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        emit(AuthAuthenticated(
          currentState.username,
          currentState.profile,
        ));
      } else {
        // Fallback: create a minimal profile
        emit(AuthAuthenticated(
          event.username,
          UserProfile(
            firstName: event.username,
            lastName: '',
            phone: '01700000000',
            deliveryAddress: 'Dhaka',
          ),
        ));
      }
    });

    on<UpdateProfile>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        emit(AuthAuthenticated(
          event.profile.fullName,
          event.profile,
        ));
      }
    });

    on<LogoutRequested>((event, emit) {
      emit(AuthUnauthenticated());
    });
  }
}
