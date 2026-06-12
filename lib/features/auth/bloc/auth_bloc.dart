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
  final UserRole role;
  final AuthMethod method;

  const SignupRequested({
    required this.profile,
    required this.role,
    required this.method,
  });

  @override
  List<Object?> get props => [profile, role, method];
}

class LoginRequested extends AuthEvent {
  final String username;
  final UserRole role;

  const LoginRequested(this.username, this.role);

  @override
  List<Object?> get props => [username, role];
}

class UpdateProfile extends AuthEvent {
  final UserProfile profile;
  const UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class SwitchRole extends AuthEvent {
  final UserRole newRole;
  const SwitchRole(this.newRole);

  @override
  List<Object?> get props => [newRole];
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
  final UserRole role;
  final UserProfile profile;

  const AuthAuthenticated(this.username, this.role, this.profile);

  @override
  List<Object?> get props => [username, role, profile];
}

// ─── Bloc ───
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<SignupRequested>((event, emit) {
      emit(AuthAuthenticated(
        event.profile.name,
        event.role,
        event.profile,
      ));
    });

    // Legacy login for dev HUD role switching
    on<LoginRequested>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        // Keep the existing profile, just switch role
        emit(AuthAuthenticated(
          currentState.username,
          event.role,
          currentState.profile,
        ));
      } else {
        // Fallback: create a minimal profile
        emit(AuthAuthenticated(
          event.username,
          event.role,
          UserProfile(
            name: event.username,
            phone: '01700000000',
            deliveryAddress: 'Gulshan-2, Dhaka',
          ),
        ));
      }
    });

    on<SwitchRole>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        emit(AuthAuthenticated(
          currentState.username,
          event.newRole,
          currentState.profile,
        ));
      }
    });

    on<UpdateProfile>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        emit(AuthAuthenticated(
          event.profile.name,
          currentState.role,
          event.profile,
        ));
      }
    });

    on<LogoutRequested>((event, emit) {
      emit(AuthUnauthenticated());
    });
  }
}
