import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/web_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/customer/presentation/screens/customer_dashboard.dart';
import 'features/customer/bloc/customer_bloc.dart';
import 'features/entry/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/entry/splash_screen.dart';

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
        ],
        child: MaterialApp(
          title: 'GoBite',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class MainRouter extends StatefulWidget {
  static bool hasSeenOnboarding = false;

  const MainRouter({super.key});

  @override
  State<MainRouter> createState() => _MainRouterState();
}

class _MainRouterState extends State<MainRouter> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          MainRouter.hasSeenOnboarding = true; // Auto-skip if logged in
          return const CustomerDashboard();
        }
        
        if (!MainRouter.hasSeenOnboarding) {
          return const OnboardingScreen();
        }
        
        // If they have seen onboarding but aren't logged in, they can browse as Guest
        return const CustomerDashboard();
      },
    );
  }
}
