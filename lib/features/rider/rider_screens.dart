import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../auth/bloc/auth_bloc.dart';
import 'bloc/rider_bloc.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  @override
  void initState() {
    super.initState();
    final name = (context.read<AuthBloc>().state as AuthAuthenticated).username;
    context.read<RiderBloc>().add(RiderStartListening(name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<RiderBloc, RiderState>(
        builder: (context, state) {
          if (state.activeDelivery != null) {
            return _buildActiveDeliveryView(state.activeDelivery!, state);
          }
          return _buildAvailableJobsView(state.availableOrders);
        },
      ),
    );
  }

  Widget _buildAvailableJobsView(List<Order> jobs) {
    final pendingJobs = jobs.where((j) => j.status == OrderStatus.readyForPickup || j.status == OrderStatus.accepted || j.status == OrderStatus.preparing).toList();

    if (pendingJobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bike, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'No delivery jobs available.',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Wait for a Customer to place an order.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingJobs.length,
      itemBuilder: (context, index) {
        final order = pendingJobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery to ${order.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '\$${(order.totalAmount * 0.1).toStringAsFixed(2)} pay', // Rider gets 10%
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.store, color: AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text('From: ${order.restaurantName}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To: ${order.deliveryAddress}',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<RiderBloc>().add(AcceptDelivery(order.id));
                  },
                  child: const Text('Accept Delivery Job'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveDeliveryView(Order order, RiderState state) {
    final isOutForDelivery = order.status == OrderStatus.outForDelivery;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order ID Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Job: ...${order.id.substring(order.id.length - 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.displayValue,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Customer details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(order.customerName),
                    subtitle: const Text('Customer'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.store, color: Colors.white),
                    ),
                    title: Text(order.restaurantName),
                    subtitle: const Text('Restaurant Pick Up'),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Simulation card when riding
          if (isOutForDelivery)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(width: 16),
                        Text(
                          'Simulating GPS Movement...',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rider coordinates: Lat ${state.currentLocation?.latitude.toStringAsFixed(4)}, Lng ${state.currentLocation?.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This matches the rider on the customer map screen live!',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Action button based on state
          if (order.status == OrderStatus.accepted || order.status == OrderStatus.preparing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Waiting for Restaurant to Finish Cooking...'),
                    ],
                  ),
                ),
              ),
            ),
          
          if (order.status == OrderStatus.readyForPickup)
            ElevatedButton.icon(
              onPressed: () {
                context.read<RiderBloc>().add(PickupOrder(order.id));
              },
              icon: const Icon(Icons.motorcycle),
              label: const Text('Pick up from Restaurant & Start Ride'),
            ),

          if (order.status == OrderStatus.outForDelivery)
            ElevatedButton.icon(
              onPressed: () {
                context.read<RiderBloc>().add(DeliverOrder(order.id));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.check),
              label: const Text('Handover to Customer (Complete Delivery)'),
            ),
        ],
      ),
    );
  }
}
