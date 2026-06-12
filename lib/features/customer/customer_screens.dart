import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../auth/bloc/auth_bloc.dart';
import 'bloc/customer_bloc.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state.activeOrder != null) {
          return const CustomerTrackingScreen();
        }
        return const CustomerMenuScreen();
      },
    );
  }
}

// --- Menu Screen ---
class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final TextEditingController _addressController =
      TextEditingController(text: '123 Market St, San Francisco, CA');

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadRestaurantMenu());
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocProvider.value(
          value: context.read<CustomerBloc>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state.cart.isEmpty) {
                      return const Center(child: Text('Your cart is empty'));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Your Order',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: state.cart.length,
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.foodItem.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.fastfood, size: 50),
                                  ),
                                ),
                                title: Text(item.foodItem.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('\$${item.foodItem.price.toStringAsFixed(2)} x ${item.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                                      onPressed: () => context.read<CustomerBloc>().add(RemoveFromCart(item.foodItem)),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                      onPressed: () => context.read<CustomerBloc>().add(AddToCart(item.foodItem)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('\$${state.cartTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: Icon(Icons.location_on, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final username = (context.read<AuthBloc>().state as AuthAuthenticated).username;
                            context.read<CustomerBloc>().add(PlaceOrder(
                                  customerName: username,
                                  deliveryAddress: _addressController.text.trim(),
                                ));
                            Navigator.pop(modalContext);
                          },
                          child: const Text('Confirm & Place Order'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoBite Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state.menuItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.menuItems.length,
            itemBuilder: (context, index) {
              final food = state.menuItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          food.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.fastfood, size: 80, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              food.description,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${food.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 36),
                        onPressed: () => context.read<CustomerBloc>().add(AddToCart(food)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.cart.fold(0, (sum, i) => sum + i.quantity)} items in cart',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      '\$${state.cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showCartSheet,
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('View Cart'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Live Tracking Screen ---
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
              // Custom Animated Live Map Widget
              Expanded(
                child: Container(
                  color: Colors.orange.shade50.withOpacity(0.4),
                  child: Stack(
                    children: [
                      // Animated background lines
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MapRoutePainter(
                            riderLocation: order.riderLocation,
                          ),
                        ),
                      ),
                      
                      // Status card overlay
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                    ],
                  ),
                ),
              ),

              // Bottom Tracking Info Panel
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
                        Text(
                          'ID: ...${order.id.substring(order.id.length - 8)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.person, color: Colors.white),
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
                          child: Text(
                            order.deliveryAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
                        child: const Text('Back to Restaurant Menu'),
                      ),
                    )
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
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.amber;
      case OrderStatus.readyForPickup:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.readyForPickup:
        return Icons.shopping_bag;
      case OrderStatus.outForDelivery:
        return Icons.motorcycle;
      case OrderStatus.delivered:
        return Icons.home;
      case OrderStatus.rejected:
        return Icons.cancel;
    }
  }
}

// --- Custom Route Painter to Draw Mock Tracking Path ---
class MapRoutePainter extends CustomPainter {
  final UserLocation? riderLocation;

  MapRoutePainter({this.riderLocation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Define fixed start and end points in canvas coordinates
    final restaurantPoint = Offset(size.width * 0.15, size.height * 0.7);
    final customerPoint = Offset(size.width * 0.85, size.height * 0.25);

    // Draw full gray route path
    final path = Path()
      ..moveTo(restaurantPoint.dx, restaurantPoint.dy)
      ..cubicTo(
        size.width * 0.3, size.height * 0.8,
        size.width * 0.6, size.height * 0.2,
        customerPoint.dx, customerPoint.dy,
      );
    canvas.drawPath(path, paint);

    // Draw Restaurant and Customer markers
    _drawMarker(canvas, restaurantPoint, Colors.red, Icons.store);
    _drawMarker(canvas, customerPoint, Colors.green, Icons.home);

    // If Rider location is available, draw them along the path
    if (riderLocation != null) {
      // Linearly interpolate rider position along path based on coordinate bounds
      // Rest: lat 37.7749, lng -122.4194
      // Cust: lat 37.7892, lng -122.4014
      const startLat = 37.7749;
      const endLat = 37.7892;
      
      final latDiff = endLat - startLat;
      double progress = (riderLocation!.latitude - startLat) / latDiff;
      progress = progress.clamp(0.0, 1.0);

      // Get point along the cubic bezier curve matching progress
      final riderPoint = _getPointOnBezier(restaurantPoint, Offset(size.width * 0.3, size.height * 0.8), Offset(size.width * 0.6, size.height * 0.2), customerPoint, progress);

      // Draw rider motorcycle
      _drawMarker(canvas, riderPoint, Colors.blue, Icons.motorcycle);
    }
  }

  void _drawMarker(Canvas canvas, Offset position, Color color, IconData icon) {
    // Draw shadow circle
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.15);
    canvas.drawCircle(position, 22, shadowPaint);

    // Draw main colored circle
    final markerPaint = Paint()..color = color;
    canvas.drawCircle(position, 18, markerPaint);

    // Draw white inner circle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, 18, borderPaint);

    // Draw small text/icon (using TextPainter since we are on Canvas)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 18,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  // Bezier curve interpolation math
  Offset _getPointOnBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    double x = uuu * p0.dx;
    x += 3 * uu * t * p1.dx;
    x += 3 * u * tt * p2.dx;
    x += ttt * p3.dx;

    double y = uuu * p0.dy;
    y += 3 * uu * t * p1.dy;
    y += 3 * u * tt * p2.dy;
    y += ttt * p3.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant MapRoutePainter oldDelegate) {
    return oldDelegate.riderLocation != riderLocation;
  }
}
