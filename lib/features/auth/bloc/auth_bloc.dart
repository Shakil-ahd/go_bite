import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/models.dart';
import '../../../core/network/web_socket_service.dart';

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
          final userMap = Map<String, dynamic>.from(jsonDecode(userJson) as Map);
          final user = UserProfile.fromJson(userMap);
          // Ensure user exists in mock db
          _users[user.email.toLowerCase().trim()] = user;
          emit(AuthAuthenticated(user.fullName, user));
        } catch (e) {
          print('AuthCheckRequested Error: $e');
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

      try {
        final profileMap = await _makeHttpPost('/auth/signup', {
          'role': 'customer',
          'profile': event.profile.copyWith(email: key).toJson(),
        });
        if (profileMap != null) {
          final profile = UserProfile.fromJson(profileMap);
          await _ensureUsersLoaded();
          _users[key] = profile;
          await _persistAllUsers();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kCurrentUser, jsonEncode(profile.toJson()));
          emit(AuthSignupSuccess(profile));
          return;
        }
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('already registered') || errorMsg.contains('registered')) {
          emit(AuthUnauthenticated(error: 'Email already registered. Please login.'));
          return;
        }
        print('HTTP Signup failed: $e. Falling back to local offline mode.');
      }

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

      final key = event.username.toLowerCase().trim();

      try {
        final profileMap = await _makeHttpPost('/auth/login', {
          'role': 'customer',
          'email': key,
          'password': event.password,
        });
        if (profileMap != null) {
          final profile = UserProfile.fromJson(profileMap);
          await _ensureUsersLoaded();
          _users[key] = profile;
          await _persistAllUsers();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kCurrentUser, jsonEncode(profile.toJson()));
          emit(AuthAuthenticated(profile.fullName, profile));
          return;
        }
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('Invalid') || errorMsg.contains('Unauthorized') || errorMsg.contains('password') || errorMsg.contains('credentials')) {
          emit(AuthUnauthenticated(error: 'Wrong password or account not found.'));
          return;
        }
        print('HTTP Login failed: $e. Falling back to local offline mode.');
      }

      await _ensureUsersLoaded();
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

        try {
          final profileMap = await _makeHttpPost('/auth/update', {
            'role': 'customer',
            'profile': event.profile.toJson(),
          });
          if (profileMap != null) {
            final profile = UserProfile.fromJson(profileMap);
            await _ensureUsersLoaded();
            _users[key] = profile;
            await _persistAllUsers();
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_kCurrentUser, jsonEncode(profile.toJson()));
            emit(AuthAuthenticated(profile.fullName, profile));
            return;
          }
        } catch (e) {
          print('HTTP UpdateProfile failed: $e. Falling back to local offline mode.');
        }

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

  Future<Map<String, dynamic>?> _makeHttpPost(String path, Map<String, dynamic> body) async {
    final baseUrl = WebSocketService.defaultUrl.replaceAll('ws://', 'http://').replaceAll('wss://', 'https://');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(response.body.isNotEmpty ? response.body : 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Load all users from SharedPreferences into memory
  Future<void> _loadAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUsersJson = prefs.getString(_kAllUsers);
      if (allUsersJson != null) {
        final Map<dynamic, dynamic> decoded = jsonDecode(allUsersJson) as Map;
        for (final entry in decoded.entries) {
          try {
            final userMap = Map<String, dynamic>.from(entry.value as Map);
            _users[entry.key.toString()] = UserProfile.fromJson(userMap);
          } catch (e) {
            print('Error parsing user ${entry.key}: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading all users: $e');
    }
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
    } catch (e) {
      print('Error saving all users: $e');
    }
  }
}
