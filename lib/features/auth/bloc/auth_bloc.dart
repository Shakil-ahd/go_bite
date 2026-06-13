import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class AuthCheckRequested extends AuthEvent {}

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
    on<AuthCheckRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('currentUser');
      if (userJson != null) {
        try {
          final user = UserProfile.fromJson(jsonDecode(userJson));
          _users[user.email] = user; // keep in mock db
          emit(AuthAuthenticated(user.fullName, user));
        } catch (e) {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<SignupRequested>((event, emit) async {
      final key = event.profile.email;
          
      _users[key] = event.profile;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(event.profile.toJson()));
      
      emit(AuthSignupSuccess(event.profile));
    });

    on<LoginRequested>((event, emit) async {
      final user = _users[event.username];
      
      if (user != null && user.password == event.password) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', jsonEncode(user.toJson()));
        emit(AuthAuthenticated(user.fullName, user));
      } else {
        // For development/mock purposes, if they enter admin credentials
        if (event.username == 'admin@admin.com' && event.password == 'admin') {
          final admin = UserProfile(
            firstName: 'Admin',
            lastName: 'User',
            phone: '01700000000',
            email: 'admin@admin.com',
            password: 'admin',
            deliveryAddress: 'Admin HQ, Dhaka',
          );
          _users['admin@admin.com'] = admin;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currentUser', jsonEncode(admin.toJson()));
          emit(AuthAuthenticated('Admin User', admin));
        } else {
          // If login fails, emit unauthenticated
          emit(AuthUnauthenticated());
        }
      }
    });

    on<UpdateProfile>((event, emit) async {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        // Update mock DB
        final key = event.profile.email;
        _users[key] = event.profile;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', jsonEncode(event.profile.toJson()));
        
        emit(AuthAuthenticated(event.profile.fullName, event.profile));
      }
    });

    on<LogoutRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      emit(AuthUnauthenticated());
    });
  }
}
