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

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {
  final String? error;
  const AuthUnauthenticated({this.error});

  @override
  List<Object?> get props => [error];
}

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
  // In-memory user database (email → profile)
  // This persists across sessions via SharedPreferences
  final Map<String, UserProfile> _users = {};

  static const _kCurrentUser = 'currentUser';
  static const _kAllUsers = 'allUsers';

  AuthBloc() : super(AuthInitial()) {
    // Load all persisted users at startup
    _loadAllUsers();

    on<AuthCheckRequested>((event, emit) async {
      await _ensureUsersLoaded();
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_kCurrentUser);
      if (userJson != null) {
        try {
          final user = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
          // Ensure user exists in mock db
          _users[user.email] = user;
          emit(AuthAuthenticated(user.fullName, user));
        } catch (e) {
          await prefs.remove(_kCurrentUser);
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    });

    on<SignupRequested>((event, emit) async {
      emit(AuthLoading());

      final key = event.profile.email.toLowerCase().trim();

      // Check if email already registered
      await _ensureUsersLoaded();
      if (_users.containsKey(key)) {
        emit(const AuthUnauthenticated(error: 'Email already registered. Please login.'));
        return;
      }

      // Save user
      final profileToSave = event.profile.copyWith(
        email: key,
      );
      _users[key] = profileToSave;

      // Persist all users & current session
      await _persistAllUsers();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCurrentUser, jsonEncode(profileToSave.toJson()));

      emit(AuthSignupSuccess(profileToSave));
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());

      await _ensureUsersLoaded();
      final key = event.username.toLowerCase().trim();
      final user = _users[key];

      if (user != null && user.password == event.password) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCurrentUser, jsonEncode(user.toJson()));
        emit(AuthAuthenticated(user.fullName, user));
      } else if (key == 'admin@admin.com' && event.password == 'admin') {
        // Dev convenience account
        final admin = UserProfile(
          firstName: 'Admin',
          lastName: 'User',
          phone: '01700000000',
          email: 'admin@admin.com',
          password: 'admin',
          deliveryAddress: 'Mirpur 10, Dhaka',
        );
        _users['admin@admin.com'] = admin;
        await _persistAllUsers();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCurrentUser, jsonEncode(admin.toJson()));
        emit(AuthAuthenticated('Admin User', admin));
      } else {
        // Provide clearer error message
        final emailExists = _users.containsKey(key);
        final errorMsg = emailExists
            ? 'Wrong password. Please try again.'
            : 'Account not found. Please sign up first.';
        emit(AuthUnauthenticated(error: errorMsg));
      }
    });

    on<UpdateProfile>((event, emit) async {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        final key = event.profile.email.toLowerCase().trim();
        _users[key] = event.profile;

        await _persistAllUsers();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCurrentUser, jsonEncode(event.profile.toJson()));

        emit(AuthAuthenticated(event.profile.fullName, event.profile));
      }
    });

    on<LogoutRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCurrentUser);
      emit(const AuthUnauthenticated());
    });
  }

  // Load all users from SharedPreferences into memory
  Future<void> _loadAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUsersJson = prefs.getString(_kAllUsers);
      if (allUsersJson != null) {
        final Map<String, dynamic> allUsers = jsonDecode(allUsersJson) as Map<String, dynamic>;
        for (final entry in allUsers.entries) {
          try {
            _users[entry.key] = UserProfile.fromJson(entry.value as Map<String, dynamic>);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // Ensure users are loaded (call before operations that need the user map)
  Future<void> _ensureUsersLoaded() async {
    if (_users.isEmpty) {
      await _loadAllUsers();
    }
  }

  // Persist all users to SharedPreferences
  Future<void> _persistAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> allUsers = {};
      for (final entry in _users.entries) {
        allUsers[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_kAllUsers, jsonEncode(allUsers));
    } catch (_) {}
  }
}
