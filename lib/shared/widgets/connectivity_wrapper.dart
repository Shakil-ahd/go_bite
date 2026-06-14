import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A widget that wraps any child and shows a full-screen "No Internet"
/// overlay when the device loses connectivity, and automatically hides
/// it when connectivity is restored.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Check initial status
    _checkConnectivity();

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      _updateConnectivity(!hasConnection);
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    _updateConnectivity(!hasConnection);
  }

  void _updateConnectivity(bool isOffline) {
    if (!mounted) return;
    if (_isOffline == isOffline) return;
    setState(() => _isOffline = isOffline);
    if (isOffline) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          FadeTransition(
            opacity: _fadeAnim,
            child: const _NoInternetScreen(),
          ),
      ],
    );
  }
}

class _NoInternetScreen extends StatefulWidget {
  const _NoInternetScreen();

  @override
  State<_NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<_NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated wifi-off icon
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE53935).withOpacity(0.3),
                          const Color(0xFFE53935).withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 60,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                const Text(
                  'ইন্টারনেট সংযোগ নেই',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।\nসংযোগ পুনরুদ্ধার হলে স্বয়ংক্রিয়ভাবে চালু হবে।',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // English subtitle
                Text(
                  'Please connect to the internet.\nApp will resume automatically.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.35),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Status dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final delay = i * 0.33;
                        final val = (_pulseController.value - delay).clamp(0.0, 1.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              Colors.white.withOpacity(0.15),
                              const Color(0xFFE53935),
                              val,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
