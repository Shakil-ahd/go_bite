import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../auth/bloc/auth_bloc.dart';
import 'bloc/restaurant_bloc.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  @override
  void initState() {
    super.initState();
    // Start listening to order events
    context.read<RestaurantBloc>().add(RestaurantStartListening());
  }

  void _showNewOrderDialog(Order order) {
    // Show a bottom notification dialog for new order alert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('New Order Alert!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Phone: ${order.customerPhone}', style: const TextStyle(color: Colors.blue)),
                Text('Address: ${order.deliveryAddress}'),
                const SizedBox(height: 12),
                const Text('Items:', style: TextStyle(decoration: TextDecoration.underline)),
                ...order.items.map((i) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(i.foodItem.category.emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Expanded(child: Text('${i.foodItem.name} x${i.quantity}', overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Text('৳${i.totalPrice.toStringAsFixed(0)}'),
                      ],
                    )),
                const Divider(),
                Text(
                  'Total: ৳${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<RestaurantBloc>().add(RejectOrder(order.id));
                  Navigator.pop(dialogContext);
                },
                child: const Text('Reject', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<RestaurantBloc>().add(AcceptOrder(order.id));
                  Navigator.pop(dialogContext);
                },
                child: const Text('Accept & Prepare'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: BlocListener<RestaurantBloc, RestaurantState>(
        listenWhen: (previous, current) => current.newOrderAlert != null,
        listener: (context, state) {
          if (state.newOrderAlert != null) {
            _showNewOrderDialog(state.newOrderAlert!);
            // Clear the alert from the state so we don't show it repeatedly
            context.read<RestaurantBloc>().add(ClearNewOrderAlert());
          }
        },
        child: BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, state) {
            if (state.orders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: AppTheme.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'No orders received yet.',
                      style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use a Customer window to place an order.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ...${order.id.substring(order.id.length - 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusChip(order.status),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: ${order.customerName}'),
                          if (order.customerPhone.isNotEmpty)
                            Text(
                              '📞 ${order.customerPhone}',
                              style: const TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Items Ordered:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      // Category badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: item.foodItem.category.gradientColors),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.foodItem.category.emoji,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('${item.foodItem.name} x ${item.quantity}'),
                                      ),
                                      Text('৳${item.totalPrice.toStringAsFixed(0)}'),
                                    ],
                                  ),
                                )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Revenue:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '৳${order.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (order.status == OrderStatus.accepted)
                              ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<RestaurantBloc>()
                                      .add(UpdateOrderStatus(order.id, OrderStatus.preparing));
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                child: const Text('Start Preparing'),
                              ),
                            if (order.status == OrderStatus.preparing)
                              ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<RestaurantBloc>()
                                      .add(UpdateOrderStatus(order.id, OrderStatus.readyForPickup));
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                child: const Text('Mark Ready for Pickup'),
                              ),
                            if (order.status == OrderStatus.readyForPickup)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delivery_dining, color: Colors.teal),
                                      SizedBox(width: 8),
                                      Text(
                                        'Awaiting Rider Pickup...',
                                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        break;
      case OrderStatus.preparing:
        color = Colors.amber.shade700;
        break;
      case OrderStatus.readyForPickup:
        color = Colors.teal;
        break;
      case OrderStatus.outForDelivery:
        color = Colors.indigo;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.displayValue,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
