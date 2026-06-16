import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/web_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/customer/presentation/screens/customer_dashboard.dart';
import 'features/customer/bloc/customer_bloc.dart';
import 'features/entry/onboarding_screen.dart';
import 'features/entry/splash_screen.dart';
import 'shared/widgets/connectivity_wrapper.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  MainRouter.hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  final customUrl = prefs.getString('custom_server_url');
  final wsUrl = customUrl ?? WebSocketService.defaultUrl;
  final ws = WebSocketService(url: wsUrl);

  runApp(GoBiteApp(webSocketService: ws));
}

class GoBiteApp extends StatelessWidget {
  final WebSocketService? webSocketService;

  const GoBiteApp({super.key, this.webSocketService});

  @override
  Widget build(BuildContext context) {
    final ws =
        webSocketService ?? WebSocketService(url: WebSocketService.defaultUrl);

    return MultiRepositoryProvider(
      providers: [RepositoryProvider<WebSocketService>.value(value: ws)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc()..add(AuthCheckRequested()),
          ),
          BlocProvider<CustomerBloc>(create: (context) => CustomerBloc(ws)),
        ],
        child: MaterialApp(
          title: 'GoBite',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => ConnectivityWrapper(child: child!),
          home: const _LifecycleWrapper(),
        ),
      ),
    );
  }
}

class _LifecycleWrapper extends StatefulWidget {
  const _LifecycleWrapper();

  @override
  State<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends State<_LifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final ws = context.read<WebSocketService>();
      ws.forceReconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
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
          MainRouter.hasSeenOnboarding = true;
          return const CustomerDashboard();
        }

        if (!MainRouter.hasSeenOnboarding) {
          return const OnboardingScreen();
        }

        return const CustomerDashboard();
      },
    );
  }
}
