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
  final String password;

  const LoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
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

class AuthSignupSuccess extends AuthState {
  final UserProfile profile;
  const AuthSignupSuccess(this.profile);
  
  @override
  List<Object?> get props => [profile];
}

class AuthAuthenticated extends AuthState {
  final String username;
  final UserProfile profile;

  const AuthAuthenticated(this.username, this.profile);

  @override
  List<Object?> get props => [username, profile];
}

// ─── Bloc ───
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Simple mock database to store profiles
  final Map<String, UserProfile> _users = {};

  AuthBloc() : super(AuthInitial()) {
    on<SignupRequested>((event, emit) {
      final key = event.method == AuthMethod.phone 
          ? event.profile.phone 
          : (event.profile.email ?? event.profile.phone);
          
      _users[key] = event.profile;
      emit(AuthSignupSuccess(event.profile));
    });

    on<LoginRequested>((event, emit) {
      final user = _users[event.username];
      
      if (user != null && user.password == event.password) {
        emit(AuthAuthenticated(user.fullName, user));
      } else {
        // For development/mock purposes, if they enter "admin", log them in directly
        if (event.username == 'admin' && event.password == 'admin') {
          final admin = UserProfile(
            firstName: 'Admin',
            lastName: 'User',
            phone: '01700000000',
            password: 'admin',
            deliveryAddress: 'Admin HQ, Dhaka',
          );
          _users['admin'] = admin;
          emit(AuthAuthenticated('Admin User', admin));
        } else {
          // If login fails, emit unauthenticated
          emit(AuthUnauthenticated());
        }
      }
    });

    on<UpdateProfile>((event, emit) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        // Update mock DB
        final key = event.profile.email ?? event.profile.phone;
        _users[key] = event.profile;
        emit(AuthAuthenticated(event.profile.fullName, event.profile));
      }
    });

    on<LogoutRequested>((event, emit) {
      emit(AuthUnauthenticated());
    });
  }
}
