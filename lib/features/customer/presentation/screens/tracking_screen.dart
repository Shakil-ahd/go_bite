import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../bloc/customer_bloc.dart';
import '../widgets/enhanced_map_painter.dart';

// ═══════════════════════════════════════════
// ──── Enhanced Live Tracking Screen ────
// ═══════════════════════════════════════════
class CustomerTrackingScreen extends StatelessWidget {
  const CustomerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
        ),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          final order = state.activeOrder;
          if (order == null) return const Center(child: Text('No active order'));

          return Column(
            children: [
              // Enhanced Map
              Expanded(
                child: Container(
                  color: const Color(0xFFE8F5E9),
                  child: Stack(
                    children: [
                      // Enhanced canvas map
                      Positioned.fill(
                        child: CustomPaint(
                          painter: EnhancedMapPainter(
                            riderLocation: order.riderLocation,
                            orderStatus: order.status,
                          ),
                        ),
                      ),

                      // Status overlay card
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(order.status),
                                    color: _getStatusColor(order.status),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Status',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      Text(
                                        order.status.displayValue,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Rider location info
                      if (order.riderLocation != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🏍️ Lat: ${order.riderLocation!.latitude.toStringAsFixed(4)}, Lng: ${order.riderLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom panel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '৳${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.motorcycle, color: Colors.white),
                      ),
                      title: Text(order.riderName ?? 'Searching for Rider...'),
                      subtitle: const Text('Your GoBite Delivery Partner'),
                      trailing: order.riderName != null
                          ? IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () {},
                            )
                          : null,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(order.deliveryAddress, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
                        child: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.accepted: return Colors.blue;
      case OrderStatus.preparing: return Colors.amber;
      case OrderStatus.readyForPickup: return Colors.teal;
      case OrderStatus.outForDelivery: return Colors.indigo;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.rejected: return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.hourglass_top;
      case OrderStatus.accepted: return Icons.check_circle;
      case OrderStatus.preparing: return Icons.restaurant;
      case OrderStatus.readyForPickup: return Icons.shopping_bag;
      case OrderStatus.outForDelivery: return Icons.motorcycle;
      case OrderStatus.delivered: return Icons.home;
      case OrderStatus.rejected: return Icons.cancel;
    }
  }
}
