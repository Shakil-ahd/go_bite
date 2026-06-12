import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/web_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/customer/bloc/customer_bloc.dart';
import 'features/customer/customer_screens.dart';
import 'features/entry/entry_screen.dart';
import 'features/restaurant/bloc/restaurant_bloc.dart';
import 'features/restaurant/restaurant_screens.dart';
import 'features/rider/bloc/rider_bloc.dart';
import 'features/rider/rider_screens.dart';
import 'shared/models/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoBiteApp());
}

class GoBiteApp extends StatelessWidget {
  final WebSocketService? webSocketService;

  const GoBiteApp({super.key, this.webSocketService});

  @override
  Widget build(BuildContext context) {
    final ws = webSocketService ?? WebSocketService(url: WebSocketService.defaultUrl);
    
    // Only connect if initializing the default service
    if (webSocketService == null) {
      ws.connect();
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WebSocketService>.value(value: ws),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(),
          ),
          BlocProvider<CustomerBloc>(
            create: (context) => CustomerBloc(ws),
          ),
          BlocProvider<RestaurantBloc>(
            create: (context) => RestaurantBloc(ws),
          ),
          BlocProvider<RiderBloc>(
            create: (context) => RiderBloc(ws),
          ),
        ],
        child: MaterialApp(
          title: 'GoBite',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const MainRouter(),
        ),
      ),
    );
  }
}

class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          // Wrap the active dashboard with a helper layout that provides a developer role switcher hud
          return Scaffold(
            body: Stack(
              children: [
                // Active screen body based on role
                _buildRoleDashboard(authState.role),

                // Floating Dev Role-Switcher Tool (only for developer testing ease!)
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingDevHud(currentRole: authState.role),
                ),
              ],
            ),
          );
        }

        // Default screen is entry login/role select
        return const EntryScreen();
      },
    );
  }

  Widget _buildRoleDashboard(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return const CustomerDashboard();
      case UserRole.restaurant:
        return const RestaurantDashboard();
      case UserRole.rider:
        return const RiderDashboard();
    }
  }
}

// --- Floating Developer Role Switcher (Utility HUD) ---
class FloatingDevHud extends StatelessWidget {
  final UserRole currentRole;

  const FloatingDevHud({super.key, required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      color: AppTheme.secondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0),
              child: Icon(Icons.developer_mode, color: Colors.orangeAccent, size: 20),
            ),
            _buildHudTab(context, UserRole.customer, Icons.shopping_bag, 'Customer'),
            _buildHudTab(context, UserRole.restaurant, Icons.store, 'Kitchen'),
            _buildHudTab(context, UserRole.rider, Icons.directions_bike, 'Rider'),
          ],
        ),
      ),
    );
  }

  Widget _buildHudTab(BuildContext context, UserRole role, IconData icon, String label) {
    final isSelected = currentRole == role;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          final authBloc = context.read<AuthBloc>();
          final currentAuthState = authBloc.state;
          if (currentAuthState is AuthAuthenticated) {
            authBloc.add(LoginRequested(currentAuthState.username, role));
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
