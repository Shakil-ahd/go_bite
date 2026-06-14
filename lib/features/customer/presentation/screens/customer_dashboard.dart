import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/customer_bloc.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import '../../../../shared/models/models.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  // Track orders that have already been rated to prevent duplicates
  final Set<String> _ratedOrderIds = {};

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadRestaurantMenu());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CustomerBloc>().add(InitializeUser(authState.profile.email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is AuthAuthenticated) {
              context.read<CustomerBloc>().add(InitializeUser(authState.profile.email));
            }
          },
        ),
        BlocListener<CustomerBloc, CustomerState>(
          listenWhen: (previous, current) {
            if (current.orderHistory.length > previous.orderHistory.length &&
                current.orderHistory.isNotEmpty) {
              final lastOrder = current.orderHistory.last;
              return lastOrder.status == OrderStatus.delivered &&
                  lastOrder.riderName != null &&
                  !_ratedOrderIds.contains(lastOrder.id);
            }
            return false;
          },
          listener: (context, state) {
            final lastOrder = state.orderHistory.last;
            if (lastOrder.status == OrderStatus.delivered &&
                lastOrder.riderName != null &&
                !_ratedOrderIds.contains(lastOrder.id)) {
              _ratedOrderIds.add(lastOrder.id);
              _showRatingDialog(context, lastOrder.riderName!);
            }
          },
        ),
      ],
      child: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state.selectedCategory != null) {
            return const CustomerMenuScreen();
          }
          return const CustomerCategoryHome();
        },
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String riderName) {
    int rating = 5;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    const Text('Order Delivered!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('How was your delivery by $riderName?', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 32,
                          ),
                          onPressed: () => setState(() => rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CustomerBloc>().add(RateRider(riderName, rating));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Thank you for rating $riderName!'), backgroundColor: Colors.green),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

